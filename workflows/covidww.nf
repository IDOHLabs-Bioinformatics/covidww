/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { FASTP              } from '../modules/nf-core/fastp/main'
include { BWAMEM2_INDEX		 } from '../modules/nf-core/bwamem2/index/main'
include { BWAMEM2_MEM		 } from '../modules/nf-core/bwamem2/mem/main'
include { SAMTOOLS_INDEX     } from '../modules/local/samtools/index/main'
include { IVAR_TRIM          } from '../modules/local/ivar/main'
include { SAMTOOLS_SORT      } from '../modules/local/samtools/sort/main'
include { FREYJA_VARIANTS    } from '../modules/nf-core/freyja/variants/main'
include { FREYJA_DEMIX       } from '../modules/local/freyja/demix/main'
include { FREYJA_CLEAN       } from '../modules/local/freyja_clean'
include { MAP_PLOT           } from '../modules/local/map_plot'
include { paramsSummaryMap       } from 'plugin/nf-validation'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_covidww_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow COVIDWW {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    ch_reference   // channel: reference genome read in from --reference_genome
    ch_adapters    // channel: fasta file with additional adapters to trim read in from --adapter_fasta
    ch_bed         // channel: bed file with primers read in from --bed_file
    ch_metadata    // channel: metadata file read in from --metadata

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // MODULE: Run FastQC
    //
    FASTQC (
        ch_samplesheet
    )

    //
    // MODULE: Run BWAmem2 index
    //
    BWAMEM2_INDEX (
        Channel.of('reference_genome').combine(ch_reference)
    )

    //
    // MODULE: Run Fastp
    //
    FASTP (
        ch_samplesheet,
        ch_adapters.first(),
        params.save_trim_fail,
        params.save_merged
    )

    //
    // MODULE: Run BWAmem2 mem
    //
    BWAMEM2_MEM (
        FASTP.out.reads,
        BWAMEM2_INDEX.out.index.first(),
        params.sort_bam
    )

    //
    // MODULE: Index the bam file
    //
    SAMTOOLS_INDEX (
        BWAMEM2_MEM.out.bam
    )

    //
    // MODULE: trim primers with iVar
    //
    IVAR_TRIM (
        SAMTOOLS_INDEX.out.bai,
        ch_bed.first()
    )

    //
    // MODULE: samtools sort
    //
    SAMTOOLS_SORT {
        IVAR_TRIM.out.bam
    }

    //
    // MODULE: Freyja find variants
    //
    FREYJA_VARIANTS (
        SAMTOOLS_SORT.out.bam,
        ch_reference.first()
    )

    //
    // MODULE: Freyja demixing
    //
    FREYJA_DEMIX (
        FREYJA_VARIANTS.out.variants
    )

    //
    // MODULE: Freyja results cleaning
    //
    FREYJA_CLEAN (
        FREYJA_DEMIX.out.demix.collect()
    )

    //
    // MODULE: Plot results on a state map
    //
    MAP_PLOT (
        FREYJA_CLEAN.out.csv,
        ch_metadata
    )

    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC.out.versions.first(),FASTP.out.versions.first(), BWAMEM2_INDEX.out.versions.first(), BWAMEM2_MEM.out.versions.first())

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(storeDir: "${params.outdir}/pipeline_info", name: 'nf_core_pipeline_software_mqc_versions.yml', sort: true, newLine: true)
        .set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config                     = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config              = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true) : Channel.empty()
    ch_multiqc_logo                       = params.multiqc_logo ? Channel.fromPath(params.multiqc_logo, checkIfExists: true) : Channel.empty()
    summary_params                        = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary                   = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: false))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
