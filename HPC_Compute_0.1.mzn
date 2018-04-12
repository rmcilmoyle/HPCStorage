/*  -----------------------------------------------------------------
**  MiniZinc Optimization of HPC Compute
**  Author: Roger McIlmoyle, Principal Solution Architect
**  Revision: 0.1, 12 Mar 2018
**
**  Objective: 
**  -----------------------------------------------------------------
**  Calculate the most efficicent HPC compute cluster knowing volume of vRAM, vRAM utilization, 
**  vCpu, vCpu utilization, hypervisor anti-affinity, cluster anti-affinity, minimum growth potential.
**
**  Datafiles: 
**  -----------------------------------------------------------------
**  vm_guest=[guestname,vram,vrampct,vcpu,vcpupct]
**  vm_guest_affinity=[guestname,guestname]
**  vm_guest_cluster_affinity=[guestname,guestname]
**  vm_guest_anti_affinity=[guestname,guestname]
**  vm_guest_anti_affinity=[guestname,guestname]
**
**
**  Assumptions: 
**  -----------------------------------------------------------------
**  Maximum Clusters = 5, there is a maximum of five compute clusters (availability zones)
**  Minimum Free RAM = 10%, on any hypervisor, 20% on any cluster 
**  Minimum Free vCPU = 10%, on any hypervisor, 20% on any cluster
**
**  Revision History:
**  -----------------------------------------------------------------
**  0.1 Initial version
**
*/

% Setup assumptions
int: MAX_CLUSTERS = 5;
int: MIN_FREE_RAM_HYPER = 78; % using interger math throughout to avoid compute and complexity, assumption hypervisor has 768GB RAM
int: MIN_FREE_VCPU = 4; % four free threads, two cores. Fact is these are essentially consumed by the hypervisor and NSX appliances
int: VM_GUESTS;
int: VM_AFFINITY;
int: VM_ANTI_AFFINITY;
int: VM_CLUSTER;
int: VM_ANTI_CLUSTER;

enum VMS;
enum VM_Fields = { vmName, vmRam, vmRamPct, vmVcpu, vmVcpuPct };
array [ 1 .. VM_GUESTS, 1 .. 5 ] of int: vm_guests;
array [ 1 .. VM_AFFINITY, 1 .. 2 ] of int: vm_affinity; 
array [ 1 .. VM_ANTI_AFFINITY, 1 .. 2 ] of int: vm_anti_affinity; % generlaly used for AD, Exchange, etc..
array [ 1 .. VM_CLUSTER, 1 .. 2 ] of int: vm_cluster; % generally this is going to be used for SAP or SAP HANA clusters
array [ 1 .. VM_ANTI_CLUSTER, 1 .. 2 ] of int: vm_anti_cluster;  % generall this is also going to be used for SAP or SAP HANA clusters

set of int: GUESTS = 1 .. VM_GUESTS;

/*  Model Assumptions and Assertions
**  -----------------------------------------------------------------
**  In affinity and anti-affinity arrays, element 0 represents no affinities or anti-affinities, i.e. the null set
*/

constraint forall( vm in GUESTS) (assert( vm_guests[vm,2] in 1 .. 256 /\ vm_guests[vm,3] in 1 .. 100 /\ vm_guests[vm,4] in 1 .. 64 /\ vm_guests[vm,5] in 1 .. 100,"Invalid virtual machine specification" )); % confirm we're working with a sane set of virtual machines

/*
** Need to pack hypervisors such that there is sufficient compute and storage(RAM) for the assigned virtual machines using the fewest hypervisors
*/

array [ GUESTS ] of var int: hypervisor_ram; % which hypervisor assuming no viloation of ram
array [ GUESTS ] of var int: hypervisor_vcpu; % which hypervisor assuming no viloation of vCPU
array [ GUESTS ] of var int: vmguest_ram; % how much ram it will actually use
array [ GUESTS ] of var int: vmguest_vcpu; % how much vCPU it will actually use which takes into account variable over-subscription

/*
** if a virtual machine routinely uses less than it's allocated RAM it's possible to pack it more densely as the hypervisor will intelengtly deal with the over-subscription
** there is inherent risk that the virtual machine may at it's own will start to use it's allocated RAM creating a resource shortage; however, this is a way to
** artificially drive vCPU to be the over-riding resource
*/
 
constraint forall( v in GUESTS)( vmguest_ram[v] = ceil( vm_guests[v,vmRam] * vm_guests[v,vmRamPct]/100 ));
constraint forall( v in GUESTS)( vmguest_vcpu[v] = ceil( vm_guests[v,vmVcpu] * vm_guests[v,vmVcpuPct]/100 ));
% bin packing global would be nice...
constraint forall( v in GUESTS) ( sum( v1 in GUESTS where hypervisor_ram[v] = hypervisor_ram[v1] )( vmguest_ram[v1] ) <= 768);
constraint forall( v in GUESTS) ( hypervisor_ram[v]>0 /\ hypervisor_ram[v]<= 100 );
constraint forall( v in GUESTS) ( sum( v1 in GUESTS where hypervisor_vcpu[v] = hypervisor_vcpu[v1])( vmguest_vcpu[v1]  ) <= 13);
constraint forall( v in GUESTS) ( hypervisor_ram[v] = hypervisor_vcpu[v] );
/*
** does not appear to be necessary to force a minimum # of hypervisors
%array [ GUESTS ] of var int: hypervisors;
%constraint forall( v in GUESTS) (hypervisor_vcpu[v]=hypervisors[hypervisor_vcpu[v]]); 
%var int: min_hypervisor = sum(h in GUESTS)(hypervisors[h]>0);
%solve minimize min_hypervisor; % just find any solution
*/

solve satisfy;