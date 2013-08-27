## Trunk vs side branch model of influenza dynamics

Want a model of an influenza tree where the trunk evolves differently than side branches.
This is reflected by different `branchRateModel`s for branches that descend from a single marked tip (trunk branches) and all other branches on the tree (side branches).
Trunk branches are scaled by a parameter &lambda; and side branches remain at 1.
The rate model thus includes the overall rate &mu;, so that trunk branches have rate &lambda; &times; &mu; and side branches have rate &mu;.

This branch rate model can be applied to different partitions on the same tree.  
We can have a sequence partition from non-epitope sites where the trunk should evolve more slowly, a sequence partition from epitope sites where the trunk should evolve more quickly and a continuous trait partition from the antigenic MDS where the trunk should diffuse more quickly.

## Implementation

```XML
<localClockModel id="">
	<treeModel idref=""/>
	<rate>
		<parameter id="branchRate" value="0.001"/>
	</rate>
	<trunk>
		<taxa idref="trunkTaxa"/>
		<parameter id="trunkTaxon" value="0" lower="0" upper="X"/>
		<parameter id="trunkRate" value="0.001"/>
	</trunk>
</localClockModel>
```

