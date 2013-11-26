## Basic trunk vs side branch implementation

Basic model of differing side branch and trunk rates is shown in [`stem.xml`](https://github.com/trvrb/stem/blob/master/spec/stem.xml).  This takes an amino acid alignment and assigns different rates to trunk and side branches.  The trunk is defined as all branches descending from a particular tip.  

Code in BEAST resides in [`LocalClockModel`](https://code.google.com/p/beast-mcmc/source/browse/trunk/src/dr/evomodel/branchratemodel/LocalClockModel.java) and [`LocalClockParser`](https://code.google.com/p/beast-mcmc/source/browse/trunk/src/dr/evomodelxml/branchratemodel/LocalClockModelParser.java).

Possible stem tips are specified in an additional `<taxa>` block:

```xml
<taxa id="stems">
	<taxon idref="A/Stockholm/6/2011"/>
	<taxon idref="A/Uppsala/3/2011"/>
	<taxon idref="A/Stockholm/5/2011"/>
	<taxon idref="A/Stockholm/7/2011"/>
	<taxon idref="A/Serbia/824/2011"/>		
</taxa>
```

Tree model follows the standard coalescent model.  Substitution model is the standard AA substitution model with gamma distributed rates across sites.  However, branch rate model follows a special `<localClockModel>`:

```xml
<localClockModel id="branchRates">
	<treeModel idref="treeModel"/>
	<rate>
		<parameter id="clock.rate" value="0.0010" lower="0.0"/>
	</rate>
	<trunk relative="true">
		<taxa idref="stems"/>
		<index>
			<parameter id="stem" value="0"/>
		</index>
		<parameter id="trunkRatio" value="1.0" lower="0.0"/>
	</trunk>
</localClockModel>
```

The `clock.rate` parameter specifies rate of side branches and `trunkRatio` specifies the multiplier on trunk branches.  The parameter `stem` is an indicator variable that specifies which stem strain to take as determining the trunk.

Operators modify `clock.rate` and `trunkRatio`, but also propose new stem indicators.

```xml
<operators id="operators">
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="clock.rate"/>
	</scaleOperator>
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="trunkRatio"/>
	</scaleOperator>
	<uniformIntegerOperator weight="5" lower="0" upper="4">
		<parameter idref="stem"/>
	</uniformIntegerOperator>	
</operators>	
```

This needs to have `upper` specified manually to match the number of possible stem strains.

Priors and MCMC is pretty standard, with `clock.rate`, `trunkRatio` and `stem` all logged.  The tree logging records whether a branch is assigned as trunk or side branch, as well as, each branch's rate:

```xml
<logTree id="treeFileLog" logEvery="1000" nexusFormat="true" fileName="stem.trees" sortTranslationTable="true">
	<treeModel idref="treeModel"/>
	<trait name="trunk" tag="trunk">
		<localClockModel idref="branchRates"/>
	</trait>
	<trait name="rate" tag="rate">
		<localClockModel idref="branchRates"/>
	</trait>
	<posterior idref="posterior"/>
</logTree>
```

## Partitioning rates across sites

A more complex model partitions rates across sites in addition to partitioning rates across trunk vs side branch.  This is shown in [`stem_partition.xml`](https://github.com/trvrb/stem/blob/master/spec/stem_partition.xml).  On the data side, this is accomplished by separating alignment positions using `<maskedPatterns>`.

Code in BEAST resides in [`maskedPatternsParser`](https://code.google.com/p/beast-mcmc/source/browse/trunk/src/dr/evoxml/MaskedPatternsParser.java).

```xml
<maskedPatterns id="epitopePatterns" negative="false">
	<alignment idref="alignment"/>
	<mask>
		0000000111110110110010100110001000000010010111100111001...
	</mask>
</maskedPatterns>

<maskedPatterns id="nonepitopePatterns" negative="true">
	<alignment idref="alignment"/>
	<mask>
		0000000111110110110010100110001000000010010111100111001...
	</mask>
</maskedPatterns>   
```

Clock models are duplicated:

```xml
<localClockModel id="epitopeRates">
	<treeModel idref="treeModel"/>
	<rate>
		<parameter id="clock.rate" value="0.0010" lower="0.0"/>
	</rate>
	<trunk relative="true">
		<taxa idref="stems"/>
		<index>
			<parameter id="stem" value="0"/>
		</index>
		<parameter id="epitopeTrunkRatio" value="1.0" lower="0.0"/>
	</trunk>
</localClockModel>

<localClockModel id="nonepitopeRates">
	<treeModel idref="treeModel"/>
	<rate>
		<parameter idref="clock.rate"/>
	</rate>
	<trunk relative="true">
		<taxa idref="stems"/>
		<index>
			<parameter idref="stem"/>
		</index>
		<parameter id="nonepitopeTrunkRatio" value="1.0" lower="0.0"/>
	</trunk>
</localClockModel>	
```

But notice they share the same `stem` parameter.

Tree likelihoods are also duplicated:

```xml
<treeLikelihood id="epitopeTreeLikelihood" useAmbiguities="false" stateTagName="states">
	<patterns idref="epitopePatterns"/>
	<treeModel idref="treeModel"/>
	<siteModel idref="siteModel"/>
	<localClockModel idref="epitopeRates"/>
</treeLikelihood>

<treeLikelihood id="nonepitopeTreeLikelihood" useAmbiguities="false" stateTagName="states">
	<patterns idref="nonepitopePatterns"/>
	<treeModel idref="treeModel"/>
	<siteModel idref="siteModel"/>
	<localClockModel idref="nonepitopeRates"/>
</treeLikelihood>	
```

Proposals include both epitope and nonepitope rates:

```xml
<operators id="operators">
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="clock.rate"/>
	</scaleOperator>
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="epitopeTrunkRatio"/>
	</scaleOperator>
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="nonepitopeTrunkRatio"/>
	</scaleOperator>	
</operators>		
```

Trees log file looks like:

```xml
<logTree id="treeFileLog" logEvery="1000" nexusFormat="true" fileName="stem_partition.trees" sortTranslationTable="true">
	<treeModel idref="treeModel"/>			
	<trait name="trunk" tag="trunk">
		<localClockModel idref="epitopeRates"/>
	</trait>
	<trait name="rate" tag="epitopeRate">
		<localClockModel idref="epitopeRates"/>
	</trait>
	<trait name="rate" tag="nonepitopeRate">
		<localClockModel idref="nonepitopeRates"/>
	</trait>						
	<posterior idref="posterior"/>
</logTree>
```

## Antigenic diffusion

Rather than focusing on sequence evolution, we can instead look at evolution of antigenic phenotype.  In this case, each virus possesses a 2D antigenic location expressed as a continuous character state on the phylogeny.  This character state evolves according a Brownian motion process that includes a stochastic diffusion term and a systematic drift term.  The rate of diffusion and the rate of drift may differ between trunk and side branches.

### Diffusion model alone

We begin with a model of fixed virus antigenic locations in [`stem_diffusion.xml`](https://github.com/trvrb/stem/blob/master/spec/stem_diffusion.xml).

Code in BEAST resides in [`IntegratedMultivariateTraitLikelihood`](https://code.google.com/p/beast-mcmc/source/browse/trunk/src/dr/evomodel/continuous/IntegratedMultivariateTraitLikelihood.java) for implementation and [`AbstractMultivariateTraitLikelihood`](https://code.google.com/p/beast-mcmc/source/browse/trunk/src/dr/evomodel/continuous/AbstractMultivariateTraitLikelihood.java) for parsing.

We include antigenic locations in the `taxa` block:

```xml
<taxa id="taxa">
	<taxon id="A/Bilthoven/15793/1968">
		<date value="1968.0" direction="forwards" units="years"/>
		<attr name="antigenic">0.0 0.0</attr>
	</taxon>
	<taxon id="A/Bilthoven/2668/1970">
		<date value="1970.0" direction="forwards" units="years"/>
		<attr name="antigenic">2.0 0.0</attr>
	</taxon>
	...
</taxa>
```

Tree model also references the trait:

```xml
<treeModel id="treeModel">
	<coalescentTree idref="startingTree"/>
	<rootHeight>
		<parameter id="treeModel.rootHeight"/>
	</rootHeight>
	<nodeHeights internalNodes="true">
		<parameter id="treeModel.internalNodeHeights"/>
	</nodeHeights>
	<nodeHeights internalNodes="true" rootNode="true">
		<parameter id="treeModel.allInternalNodeHeights"/>
	</nodeHeights>
	<nodeTraits name="antigenic" rootNode="false" internalNodes="false" leafNodes="true" traitDimension="2">
		<parameter id="leaf.antigenic"/>
	</nodeTraits>		
</treeModel>
```

We estimate the virus phylogeny in the standard fashion using `treeLikelihood`.  To model the diffusion process we create a `multivariateDiffusionModel` and fix the diffusion kernel to be equal in dimensions 1 and 2 and include no correlation:

```xml
<multivariateDiffusionModel id="diffusionModel">
	<precisionMatrix>
		<matrixParameter id="precisionMatrix">
			<parameter id="col1" value="1 0"/>
			<parameter id="col2" value="0 1"/>
		</matrixParameter>
	</precisionMatrix>
</multivariateDiffusionModel>
```

We set up separate trunk/side branch clock models for rate of drift along dimension 1 and rate of diffusion and we fix drift along dimension 2 to `0.0`:

```xml
<localClockModel id="diffusionRates">
	<treeModel idref="treeModel"/>
	<rate>
		<parameter id="diffusion.rate" value="1.0" lower="0.0"/>
	</rate>
	<trunk relative="true">
		<taxa idref="stems"/>
		<index>
			<parameter id="stem" value="0"/>
		</index>
		<parameter id="diffusionTrunkRatio" value="1.0" lower="0.0"/>
	</trunk>
</localClockModel>		
	
<localClockModel id="driftRates">
	<treeModel idref="treeModel"/>
	<rate>
		<parameter id="drift.rate" value="1.0" lower="0.0"/>
	</rate>
	<trunk relative="true">
		<taxa idref="stems"/>
		<index>
			<parameter idref="stem"/>
		</index>
		<parameter id="driftTrunkRatio" value="1.0" lower="0.0"/>
	</trunk>
</localClockModel>	

<strictClockBranchRates id="driftRates.d2">
	<rate>
		<parameter id="drift.rate.d2" value="0.0"/>
	</rate>
</strictClockBranchRates>	
```

Again, the `stem` parameter is shared between clock models.

These plug into a trait likelihood:

```xml
<multivariateTraitLikelihood id="traitLikelihood" traitName="antigenic" 
							 useTreeLength="true" scaleByTime="false" 
							 reportAsMultivariate="true" 
							 integrateInternalTraits="true"
							 cacheBranches="true">
	<multivariateDiffusionModel idref="diffusionModel"/>		
	<treeModel idref="treeModel"/>			
	<traitParameter>
		<parameter idref="leaf.antigenic"/>
	</traitParameter>
	<conjugateRootPrior>
		<meanParameter>
			<parameter value="0 0"/>
		</meanParameter>
		<priorSampleSize>
			<parameter value="1"/>
		</priorSampleSize>
	</conjugateRootPrior>
	<localClockModel idref="diffusionRates"/>	
	<driftModels>
		<localClockModel idref="driftRates"/>
		<strictClockBranchRates idref="driftRates.d2"/>			
	</driftModels>
</multivariateTraitLikelihood>	
```

Operators include proposals on drift and diffusion rates and ratios, as well as the `stem` parameter:

```xml
<operators id="operators">
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="drift.rate"/>
	</scaleOperator>
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="driftTrunkRatio"/>
	</scaleOperator>
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="diffusion.rate"/>
	</scaleOperator>
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="diffusionTrunkRatio"/>
	</scaleOperator>	
	<uniformIntegerOperator weight="5" lower="0" upper="4">
		<parameter idref="stem"/>
	</uniformIntegerOperator>		
</operators>		
```

Priors are on drift and diffusion rates and ratios:

```xml
<prior id="prior">
	<exponentialPrior mean="1.0" offset="0.0">
		<parameter idref="drift.rate"/>
	</exponentialPrior>			
	<exponentialPrior mean="1.0" offset="0.0">
		<parameter idref="driftTrunkRatio"/>
	</exponentialPrior>	
	<exponentialPrior mean="1.0" offset="0.0">
		<parameter idref="diffusion.rate"/>
	</exponentialPrior>			
	<exponentialPrior mean="1.0" offset="0.0">
		<parameter idref="diffusionTrunkRatio"/>
	</exponentialPrior>	
</prior>	
```

and `traitLikelihood` appears along with `treeLikelihood` in the `likelihood` block.

Trees have antigenic locations as well as rates logged:

```xml
<logTree id="treeFileLog" logEvery="1000" nexusFormat="true" fileName="stem_diffusion.trees" sortTranslationTable="true">
	<treeModel idref="treeModel"/>
	<trait name="trunk" tag="trunk">
		<localClockModel idref="driftRates"/>
	</trait>
	<trait name="rate" tag="driftRate">
		<localClockModel idref="driftRates"/>
	</trait>
	<trait name="rate" tag="diffusionRate">
		<localClockModel idref="diffusionRates"/>
	</trait>
	<multivariateTraitLikelihood idref="traitLikelihood"/>						
	<posterior idref="posterior"/>
</logTree>
```

### Including cartographic estimation from HI data

In this case, everything from the diffusion model is included, but tips are no longer fixed and their locations are estimated from HI data.  And in addition, serum locations and potencies are also estimated.  This model is shown in [`stem_antigenic.xml`](https://github.com/trvrb/stem/blob/master/spec/stem_antigenic.xml).

Code in BEAST resides in [`AntigenicLikelihood`](https://code.google.com/p/beast-mcmc/source/browse/trunk/src/dr/evomodel/antigenic/AntigenicLikelihood.java).

This is accomplished by including an antigenic likelihood that references tip traits as well as a [table of HI data](https://github.com/trvrb/stem/blob/master/spec/test_hi_padded.tsv):

```xml
<antigenicLikelihood id="antigenicLikelihood" 
							fileName="test_hi_padded.tsv"
							mdsDimension="2"
							intervalWidth="1.0">
	<virusLocations>
		<matrixParameter id="virusLocations"/>
	</virusLocations>	
	<serumLocations>
		<matrixParameter id="serumLocations"/>
	</serumLocations>			
	<tipTrait>
		<parameter idref="leaf.antigenic"/>
	</tipTrait>			
	<mdsPrecision>
		<parameter id="mds.precision" value="1.0" lower="0.0"/>
	</mdsPrecision>
	<serumPotencies>
		<parameter id="serumPotencies"/>
	</serumPotencies>	
</antigenicLikelihood>  
```

Serum potencies are estimated in a hierarchical fashion:

```xml
<distributionLikelihood id="serumPotencies.hpm">
	<data>
		<parameter idref="serumPotencies"/>
	</data>
	<distribution>
		<normalDistributionModel>
			<mean>
				<parameter id="serumPotencies.mean" value="10.0" lower="0.0"/>
			</mean>
			<precision>
				<parameter id="serumPotencies.precision" value="1.0" lower="0.0"/>
			</precision>
		</normalDistributionModel>
	</distribution>
</distributionLikelihood>
```

This requires proposals on virus locations, serum locations, serum potencies, MDS precision, serum potencies mean and serum potencies precision:

```xml
<operators id="operators">
	<randomWalkOperator windowSize="1.0" weight="100">
		<parameter idref="virusLocations"/>
	</randomWalkOperator>
	<randomWalkOperator windowSize="1.0" weight="100">
		<parameter idref="serumLocations"/>
	</randomWalkOperator>		
	<scaleOperator scaleFactor="0.99" weight="1">
		<parameter idref="mds.precision"/>
	</scaleOperator>	
	<scaleOperator scaleFactor="0.99" weight="10">
		<parameter idref="serumPotencies"/>
	</scaleOperator>			
	<scaleOperator scaleFactor="0.99" weight="1">
		<parameter idref="serumPotencies.mean"/>
	</scaleOperator>	
	<scaleOperator scaleFactor="0.99" weight="1">
		<parameter idref="serumPotencies.precision"/>
	</scaleOperator>
</operators>
```

The prior on virus locations is taken care of by the diffusion process, but serum locations and serum potencies need priors, as does MDS precision:

```xml
<prior id="prior">
	<exponentialPrior mean="1.0" offset="0.0">
		<parameter idref="mds.precision"/>
	</exponentialPrior>	
	<exponentialPrior mean="1.0" offset="0.0">
		<parameter idref="serumPotencies.precision"/>
	</exponentialPrior>					
	<distributionLikelihood idref="serumPotencies.hpm"/>	
</prior>
```

*Serum locations should have a drift prior.  This needs to be specified.*

Virus locations, serum locations and serum potencies are logged to separate files:

```xml
<log id="fileLog2" logEvery="1000" fileName="stem_antigenic.virusLocs.log">
	<parameter idref="virusLocations"/>
</log>

<log id="fileLog3" logEvery="1000" fileName="stem_antigenic.serumLocs.log">
	<parameter idref="serumLocations"/>
</log>		

<log id="fileLog4" logEvery="1000" fileName="stem_antigenic.serumPotencies.log">
	<parameter idref="serumPotencies"/>
</log>		
```

Tree is logged just as before.