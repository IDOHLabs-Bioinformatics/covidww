# covidww: Output

## Introduction

This document describes the output produced by the pipeline.
The directories listed below will be created in the results directory after the pipeline has finished. All paths are
relative to the top-level ```OUTDIR``` directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [FastQC](#fastqc) - Raw read QC
- [FASTP](#fastp) - Quality and adapter trimming
- [BWA-mem2](#bwa-mem2) - Alignment
- [samtools stats](#samtools) - Alignment QC
- [iVar](#iVar) - Primer trimming
- [Freyja](#Freyja) - Variant calling and lineage demixing
- [Freyja clean](#Freyja clean) - Clean Freyja results
- [Summary](#Summary) - Demixing summary
- [Map plot](#Map plot) - Visualize with location metadata
- [MultiQC](#multiqc) - Aggregate report describing results and QC from the whole pipeline
- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution

### FastQC

<details markdown="1">
<summary>Output files</summary>

- `fastqc/`
  - `*_fastqc.html`: FastQC report containing quality metrics.
  - `*_fastqc.zip`: Zip archive containing the FastQC report, tab-delimited data file and plot images.

</details>

[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your sequenced reads. It provides information about the quality score 
distribution across your reads, per base sequence content (%A/T/G/C), adapter contamination and overrepresented sequences. 
For further reading and documentation see the [FastQC help pages](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).

![MultiQC - FastQC sequence counts plot](images/mqc_fastqc_counts.png)

![MultiQC - FastQC mean quality scores plot](images/mqc_fastqc_quality.png)

![MultiQC - FastQC adapter content plot](images/mqc_fastqc_adapter.png)

:::note
The FastQC plots displayed in the MultiQC report shows _untrimmed_ reads. They may contain adapter sequence and 
potentially regions with low quality.
:::

### FastP

<details markdown="1">
<summary>Output files</summary>

- `fastp/`
  - `*fastp.fastq.gz`: Trimmed reads
  - `*.json`: json file of the QC
  - `*.html`: html file with the QC report
  - `*.log`: log report of Fastp
  - `*.fail.fastq.gz`: reads failing QC *optional*
  - `*.merged.fastq.gz`: merged reads *optional*

</details>

[Fastp](https://github.com/OpenGene/fastp) is designed to perform all necessary preprocessing of FastQ in an ultra-fast manner. It performs quality 
profiling, filters out bad reads, cuts low quality bases, trims reads in front and tail, cuts adapters, corrects
mismatches in overlapped paired end reads, and visualizes quality control and reports it in a json format for further
interpreting.


### BWA-mem2

<details markdown="1">
<summary>Output files</summary>

- `BWA-mem2/`
  - `*.bam`: Read alignment in bam format
  - `bwamem2/*`: Index of reference genome

</details>

[BWA-mem2](https://github.com/bwa-mem2/bwa-mem2) performs read alignment to the SARS-CoV-2 reference genome.

### Samtools
<details markdown="1">
<summary>Output files</summary>

- `samtools/`
  - `*.stats`: Read alignment in bam format
  - `*.bam`: Sorted bam files
  - `*.bai`: bam index files

</details>

[Samtools](https://www.htslib.org/) provides useful functions throughout this pipeline, indexing and sorting alignment and providing
alignment QC. The samtools alignment QC adds percent reads mapped and many alignment stats to the MultiQC report.

### iVar

<details markdown="1">
<summary>Output files</summary>

- `ivar/`
  - `*trimmed.bam`: Read alignment with primers trimmed in bam format
  - `*.log`: Log file of trimming process

</details>

[iVar](https://andersen-lab.github.io/ivar/html/index.html) trims the primers used to generate amplicons from the reads so that only the sequence data from the samples 
is analyzed, and not the primers

### Freyja

<details markdown="1">
<summary>Output files</summary>

- `freyja/`
  - `*.variants.tsv`: Tab separated file of variants
  - `*.depth.tsv`: Tab separated file of read depths per base
  - `*demix.txt`: Text file containing the demix results
  - `wastewater_analysis_<run date>.csv`: Lineage deconvolution results

</details>

[Freyja](https://github.com/andersen-lab/Freyja/tree/main/freyja) generates variant calls and read depths in an initial step. Once those are generated, it is able to 
calculate the relative abundances of lineages within the sample. 


### Summary

<details markdown="1">
<summary>Output files</summary>

- `summary/`
  - `*.pdf`: Visualization of the demix results

</details>

Summary creates pie charts of the demixing results for the samples.

### Map Plot

<details markdown="1">
<summary>Output files</summary>

- `map/`
  - `abundance_bar_<run date>.png`: Plot of the demix results on a map
  - `abundance_map_<run data>.png`: Bar plot of the detected variants per city
  - `metadata_merged_demix*.csv`: File with the data used for the map to see what was filtered out for readability

</details>

Map plot runs if metadata containing the Sample, City, and State is provided, and it will plot the demixing results on
the map to visualize the outcome spatially. It also generates a bar plot showing the lineage abundance per city to view
in more detail.



### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  - `multiqc_plots/`: directory containing static images from the report in various formats.

</details>

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. 
Most of the pipeline QC results are visualised in the report.

Results generated by MultiQC collate pipeline QC from supported tools e.g. FastQC. The pipeline has special steps which 
also allow the software versions to be reported in the MultiQC output for future traceability. For more information 
about how to use MultiQC reports, see <http://multiqc.info>.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameters are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.
  - Parameters used by the pipeline run: `params.json`.

</details>


[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution 
of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with
other information such as launch commands, run times and resource usage.
