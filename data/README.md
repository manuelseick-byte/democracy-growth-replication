# Data

The replication scripts expect the main dataset to be located at:

`data/DDCGdata_final.dta`

The dataset is **not included in this repository** because it originates from the replication materials for Acemoglu, Naidu, Restrepo, and Robinson (2019), *Democracy Does Cause Growth*.

Before running the code:

1. Obtain the original replication data from the authors' official replication package / journal archive.
2. Place the required dataset in this folder as `DDCGdata_final.dta`.
3. Run `code/00_setup.do` from the repository root.

## Important

The current cleaned scripts originally referred to `DDCGdata_final.dta` in the project root. For a final public release, the scripts should be standardized to read the file from this `data/` directory. This repository draft intentionally does not redistribute third-party data.
