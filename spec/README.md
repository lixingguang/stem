## Basic trunk vs side branch implementation

Basic model of differing side branch and trunk rates is shown in `stem.xml`.  This takes an amino acid alignment and assigns different rates to trunk and side branches.  The trunk is defined as all branches descending from a particular tip.  

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
		<parameter id="branch.rate" value="0.0010" lower="0.0"/>
	</rate>
	<trunk>
		<taxa idref="stems"/>
		<index>
			<parameter id="stem" value="0"/>
		</index>
		<parameter id="trunk.rate" value="0.001"/>
	</trunk>
</localClockModel>
```

The `branch.rate` parameter specifies rate of side branches and `trunk.rate` specifies the rate of trunk branches.  The parameter `stem` is an indicator variable that specifies which stem strain to take as determining the trunk.

Operators modify `branch.rate` and `trunk.rate`, but also propose new stem indicators.

```xml
<operators id="operators">
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="branch.rate"/>
	</scaleOperator>
	<scaleOperator scaleFactor="0.75" weight="3">
		<parameter idref="trunk.rate"/>
	</scaleOperator>
	<uniformIntegerOperator weight="5" lower="0" upper="4">
		<parameter idref="stem"/>
	</uniformIntegerOperator>	
</operators>	
```

This needs to have `upper` specified manually to match the number of possible stem strains.

Priors and MCMC is pretty standard, with `branch.rate`, `trunk.rate` and `stem` all logged.  The tree logging gives the rate of branch, but also whether it's assigned as trunk or side branch:

```xml
<logTree id="treeFileLog" logEvery="1000" nexusFormat="true" fileName="stem.trees" sortTranslationTable="true">
	<treeModel idref="treeModel"/>
	<trait name="rate" tag="rate">
		<localClockModel idref="branchRates"/>
	</trait>
	<trait name="trunk" tag="trunk">
		<localClockModel idref="branchRates"/>
	</trait>
	<posterior idref="posterior"/>
</logTree>
```

## Partitioning rates across sites

Todo:

```xml
	<maskedPatterns id="maskedPatterns" negative="true">
		<alignment idref="alignment"/>
		<mask>
			011010101010100010100101...
		</mask>
	</maskedPatterns>
```
