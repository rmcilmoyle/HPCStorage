% testing Git...

/*  ------------------------------------------------------------------
**  HPC Storage Analysis
**  Author: Roger McIlmoyle
**  Revision: 0.1
**  Revision Date: 15-03-2018
**  
**  Purpose:
**  ------------------------------------------------------------------
**  Determine the optimal arrangement of vmware datastores given storage
**  clusters will not be used, knowing vm volumes, sizes, iops.
**
**  Revision History
**  ------------------------------------------------------------------
**  0.1  Initial release
**
*/

enum eVOLUMES;  % set of volumes where volume name is unique
set of int: sVOLS = 1 .. card(eVOLUMES);

enum eDATASTORES; % set of available datastores
set of int: sDATASTORES = 1 .. card(eDATASTORES);
set of int: vDATASTORES = 0 .. card(eDATASTORES); 

array [sVOLS] of int: iVol_size;
array [sVOLS] of int: iVol_iops;
array [sVOLS] of var int: iVol_peakiops;
array [sDATASTORES] of int: iDatastore_size; % capacity of each datastore, the capacity represents the usable capacity in GB
array [sDATASTORES] of int: iDatastore_iops; % capacity of each datastore, the capacity represents the usable capacity in IOPS
array [sDATASTORES] of int: iDatastore_cost; % cost for each datastore


array [sVOLS] of var int: iVol_ds_size;
array [sVOLS] of var int: iVol_ds_iops;
array [sDATASTORES] of var vDATASTORES: iDS_used;

include "bin_packing_capa.mzn";
constraint bin_packing_capa(iDatastore_size,iVol_ds_size,iVol_size);
constraint bin_packing_capa(iDatastore_iops,iVol_ds_iops,iVol_iops);

constraint forall( v in sVOLS ) ( iVol_ds_size[v] = iVol_ds_iops[v] ); % ensure Datastore assignement is the same for IOPS and capacity
%constraint forall( v in sVOLS where iVol_ds_iops[v]>0) ( sum( v1 in sVOLS where iVol_ds_iops[v] = iVol_ds_iops[v1]) ( iVol_iops[v1] ) <=  iDatastore_iops[iVol_ds_iops[v]] - iVol_peakiops[v] + iVol_iops[v]  ); % ensure there is headroom for virtual machine to peak IOPS
constraint forall( v in sVOLS) ( iDS_used[iVol_ds_size[v]] = 1 ); % ensure every volume is assigned a datastore

%var int: cost_price = sum( d in sDATASTORES where iDS_used[d]>0 )(iDatastore_cost[d]);

%solve::seq_search( [  int_search(iDatastore_size,smallest,indomain_min,complete),int_search(iDatastore_iops,smallest,indomain_min,complete) ]) satisfy;
solve satisfy;                      

%output ["Price  := \(fix(cost_price))\n"];