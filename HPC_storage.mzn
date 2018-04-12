/* VMware storage optimization
** Determine the optimal storage given a database of virtual machines where each has multiple volumes (GB, growth rate), defined by a volume of storage and IOPS (average, maximum)
**
** Version 1.0
** 1.0  05-03-2018  Initial version
**
*/
int: storage_increment = 500; %GB, minimum storage increment
int: max_datastore = 16384; %maximum datastore size
int: storage_reservation = 1638; % minimum storage reservation 10%
set of int: TIERS = 1 .. 5; % available storage TIERS]
set of int: DS_SIZE = 1 .. 32; % # of available datastore sizes in 500GB increments
% variables found in datafile
enum VM_VOLS;
int: total_storage; 
array [VM_VOLS]  of int: vm_vol_size;
array [VM_VOLS]  of int: vm_vol_iops; 
array [TIERS] of var int: ds_size;
array [TIERS] of var int: ds_iops;
array [ TIERS] of int: storage_tiers = [ 1953, 976, 244, 48, 12 ]; % available storage tiers in IOPS ( 4000,2000,500,100,25 ) adjusted to 500GB increments
array [ TIERS ] of int: storage_price = [ 20, 10, 7, 5, 3 ]; % storage pricing in cents, avoids floating point math
array [ TIERS, DS_SIZE, 1 .. 21 ] of var int: datastores;
include "bin_packing_capa.mzn";


solve satisfy;