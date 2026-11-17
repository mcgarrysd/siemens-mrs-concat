# Siemens MRS conversion and concatenation

This repository contains two small shell scripts for Siemens spectroscopy data:

- `convert_directory.sh` converts every top-level Siemens Twix `.dat` file in one directory to NIfTI-MRS.
- `merge_pair.sh` concatenates two selected NIfTI-MRS acquisitions along `DIM_DYN`.

The scripts do not decide which files belong together. Pair selection and acquisition order remain explicit user inputs. Water-reference files are converted but are not concatenated with the metabolite data.

## Requirements

- Bash
- [`spec2nii`](https://pages.fmrib.ox.ac.uk/fsl/fsl_mrs/data_conversion.html)
- [`mrs_tools`](https://wtclarke.github.io/nifti_mrs_tools/mrs_tools.html), provided by the `nifti_mrs` package installed with `spec2nii`

Confirm that both commands are available:

```bash
spec2nii --version
mrs_tools -v
```

The scripts have been tested with `spec2nii` 0.8.5 and `mrs_tools` 1.3.3.

## Siemens Twix dimensions

Run the following command to inspect a Twix file before conversion:

```bash
spec2nii twix -v acquisition.dat
```

The converter expects the `image` data to contain these Siemens loop counters:

| Twix name | Meaning in the tested data | NIfTI-MRS representation |
| --- | --- | --- |
| `Col` | Complex time-domain points in each FID | Spectral dimension |
| `Cha` | Receive-coil channels | `DIM_COIL` |
| `Set` | Repeated acquisitions or averages | `DIM_DYN` |
| `Eco` | Two editing conditions, when present | `DIM_EDIT` |

`Eco` is a generic Siemens echo-loop counter and is not universally an editing dimension. This workflow maps it to `DIM_EDIT` because that is how the tested edited sequence uses it. The script stops if `Cha` or `Set` is absent rather than guessing another mapping.

Two useful references are:

- [FSL-MRS: Handling and Inspecting Data from the Scanner](https://pages.fmrib.ox.ac.uk/fsl/fsl_mrs_practicals/ch3_data_from_the_scanner.html)
- [NIfTI-MRS format specification](https://github.com/wtclarke/mrs_nifti_standard/blob/master/specification.MD)

## 1. Convert one subject directory

From a directory containing the six `.dat` files for one subject, run the converter without arguments to write the NIfTI-MRS files into the same directory:

```bash
cd /path/to/subject_directory
/path/to/siemens-mrs-concat/convert_directory.sh
```

To keep the inputs and outputs in separate directories, supply both paths:

```bash
./convert_directory.sh /path/to/subject_directory /path/to/nifti_output
```

The script:

- converts only `.dat` files directly inside the input directory;
- converts the `image` data from each file;
- maps `Cha` to `DIM_COIL` and `Set` to `DIM_DYN`;
- also maps `Eco` to `DIM_EDIT` when that loop is present;
- uses the input basename for each `.nii.gz` output.

The script does not anonymize the converted headers. Review the NIfTI-MRS metadata before sharing converted data.

## 2. Concatenate each metabolite pair

Run the merge once for the unedited pair and once for the edited pair:

```bash
./merge_pair.sh \
    /path/to/first_acquisition.nii.gz \
    /path/to/second_acquisition.nii.gz \
    /path/to/combined_acquisition.nii.gz
```

The script runs:

```bash
mrs_tools merge --files FILE_1 FILE_2 --dim DIM_DYN
```

and then prints `mrs_tools info` for the result.

Use `DIM_DYN` for both the unedited and edited acquisition pairs. Each edited file already contains its two editing conditions in `DIM_EDIT`; the two interrupted files contain different blocks of dynamics, so they are concatenated along `DIM_DYN` while `DIM_EDIT` is preserved. The `Eco` to `DIM_EDIT` mapping happens during conversion, not during merging.

The input order is retained. `mrs_tools` requires matching non-`DIM_DYN` shapes and dimension tags, and it uses the first file as the source of spatial and other non-dynamic header information.

Do not include the water-reference file in this merge. Supply the selected water reference separately to the downstream analysis software.
