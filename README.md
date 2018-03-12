# multi-te
Retrospective gating, reconstruction, and mapping of pulmonary multi-TE UTE MRI.

## Functionality
There are multiple parts to this project. Each is designed to operate independently of the others.

The ultimate goal is for this project to be able to use data acquired using a variable number of TEs and produce output accordingly (i.e. gate, reconstruct, map data collected with one or multiple TEs). If done right, this should be easy & with minimal code editing.

Another long-term goal: further separate the logic for each sub-package routine to enable a 'plug and play' design for different reconstruction/mapping algorithms.

## Sub-packages

### Retrospective Gating
Examines the first and second derivatives of the leading phase of the FID information (for each TE) and bins the data according to the points corresponding to end expiration and end inspiration. This is done to minimize image artifacts due to respiratory motion of the subject being imaged.

### Image Reconstruction
Performs reconstrcution of MR images from gated k-space information. **Note:** this routine uses `MEX` files to interface with `C` files that perform gridding of k-space data to a Cartesian system.

### T2* Mapping
* Currently calculates T2* as an average of the TEs.
* Involves creating binary masks of the lungs prior to masking.
* Highlights T2* differences between lung parenchyma, vasculature, and fibrotic tissue.

---

## Organization & Operation
This package operates with a `main` file that accepts several user inputs in order execute a full processing routine for a selected dataset. This can be tuned with a simple input file written in YAML. Alternatively, the `gating`, `mapping`, and `reconstruction` packages can be used separately, as they are self contained. If you wish to write a different flavor of `main` or just use the sub-packages from the command line, you should be able to do so. Use the `help` command to see the contents of each package folder (e.g. `help gating`).

### Testing
This package contains unit tests that can be run to make sure things still behave as expected. New tests can be easily written to fit your needs.

### Bugs
Please report any bugs/weird behavior by creating an issue.

### YAML-Matlab
This project uses an input file written in [YAML](http://yaml.org/) to simplify execution and reduce hard-coding. The YAML file is read using [YAMLMatlab](https://code.google.com/archive/p/yamlmatlab/)
