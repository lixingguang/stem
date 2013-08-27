## Picking influenza stem strains

### Trunk vs side branch rate models

Want a model of an influenza tree where the trunk evolves differently than side branches.
This is reflected by different branchRateModels for branches that descend from a single marked tip (trunk branches) and all other branches on the tree (side branches).
Trunk branches are scaled by a parameter &lambda; and side branches remain at 1.
The rate model thus includes the overall rate &mu;, so that trunk branches have rate &lambda; &times; &mu; and side branches have rate &mu;.

This branch rate model can be applied to different partitions on the same tree.  
We can have a sequence partition from non-epitope sites where the trunk should evolve more slowly, a sequence partition from epitope sites where the trunk should evolve more quickly and a continuous trait partition from the antigenic MDS where the trunk should diffuse more quickly.

### Tip to trunk mapping

Want to select a single strain from the set of contemporaneous strains that is most trunk-linke in its evolution.
Here, we pick an index for the initial stem taxon from this set and operate on this index to choose new stems over the MCMC.

![](https://raw.github.com/trvrb/mk/master/figures/futuretree.png)

### Data

Start with the 402 H3N2 viruses from the [flux](https://github.com/trvrb/flux) analysis.
These have an amino acid alignment of 330 characters.


### Implementation

```XML
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

```XML
	<operators id="operators">
		<scaleOperator scaleFactor="0.75" weight="3">
			<parameter idref="branch.rate"/>
		</scaleOperator>
		<scaleOperator scaleFactor="0.75" weight="3">
			<parameter idref="trunk.rate"/>
		</scaleOperator>
		<upDownOperator scaleFactor="0.75" weight="3">
			<up>
				<parameter idref="branch.rate"/>
			</up>
			<down>
				<parameter idref="treeModel.allInternalNodeHeights"/>
			</down>
		</upDownOperator>
		<uniformIntegerOperator weight="5" lower="0" upper="3">
			<parameter idref="stem"/>
		</uniformIntegerOperator>		
	</operators>	
```

```XML
	<log id="fileLog" logEvery="1000" fileName="testTrunk.log" overwrite="false">
		<parameter idref="branch.rate"/>
		<parameter idref="trunk.rate"/>
		<parameter idref="stem"/>
	</log>		
```

```XML
	<logTree id="treeFileLog" logEvery="1000" nexusFormat="true" fileName="testTrunk.trees" sortTranslationTable="true">
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



