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

Tree model follows the standard coalescent model.  Substitution model is the standard AA substitution model.  However, branch rate model follows a special `<localClockModel>`:

```xml
<localClockModel id="branchRates">
	<treeModel idref="treeModel"/>
	<rate>
		<parameter id="branchRate" value="0.0010" lower="0.0"/>
	</rate>
	<trunk>
		<taxa idref="stems"/>
		<index>
			<parameter id="stem" value="0"/>
		</index>
		<parameter id="trunkRate" value="0.001"/>
	</trunk>
</localClockModel>
```

The `branchRate` parameter specifies rate of side branches and `trunkRate` specifies the rate of trunk branches.  The parameter `stem` is an indicator variable that specifies which stem strain to take as determining the trunk.

Operators modify `branchRate` and `trunkRate`, but also propose new stem indicators.

```xml
<operators id="operators">
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="branchRate"/>
	</scaleOperator>
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="trunkRate"/>
	</scaleOperator>
	<uniformIntegerOperator weight="5" lower="0" upper="4">
		<parameter idref="stem"/>
	</uniformIntegerOperator>	
</operators>	
```

This needs to have `upper` specified manually to match the number of possible stem strains.

Priors and MCMC is pretty standard, with `branchRate`, `trunkRate` and `stem` all logged.  The tree logging records whether a branch is assigned as trunk or side branch:

```xml
<logTree id="treeFileLog" logEvery="1000" nexusFormat="true" fileName="stem.trees" sortTranslationTable="true">
	<treeModel idref="treeModel"/>
	<trait name="trunk" tag="trunk">
		<localClockModel idref="branchRates"/>
	</trait>
	<posterior idref="posterior"/>
</logTree>
```

## Partitioning rates across sites

A more complex model partitions rates across sites in addition to partitioning rates across trunk vs side branch.  This is shown in [`stem_partition.xml`](https://github.com/trvrb/stem/blob/master/spec/stem_partition.xml).  On the data side, this is accomplished by separating alignment positions using `<maskedPatterns>`.

Code in BEAST resides in [`maskedPatternsParser`](https://code.google.com/p/beast-mcmc/source/browse/trunk/src/dr/evoxml/MaskedPatternsParser.java).

```xml
<maskedPatterns id="epitopePatterns" negative="true">
	<alignment idref="alignment"/>
	<mask>
		0000000111110110110010100110001000000010010111100111001...
	</mask>
</maskedPatterns>

<maskedPatterns id="nonepitopePatterns" negative="false">
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
		<parameter id="epitopeBranchRate" value="0.0010" lower="0.0"/>
	</rate>
	<trunk>
		<taxa idref="stems"/>
		<index>
			<parameter id="stem" value="0"/>
		</index>
		<parameter id="epitopeTrunkRate" value="0.001"/>
	</trunk>
</localClockModel>

<localClockModel id="nonepitopeRates">
	<treeModel idref="treeModel"/>
	<rate>
		<parameter id="nonepitopeBranchRate" value="0.0010" lower="0.0"/>
	</rate>
	<trunk>
		<taxa idref="stems"/>
		<index>
			<parameter idref="stem"/>
		</index>
		<parameter id="nonepitopeTrunkRate" value="0.001"/>
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
		<parameter idref="epitopeBranchRate"/>
	</scaleOperator>
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="epitopeTrunkRate"/>
	</scaleOperator>
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="nonepitopeBranchRate"/>
	</scaleOperator>
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="nonepitopeTrunkRate"/>
	</scaleOperator>	
</operators>		
```

