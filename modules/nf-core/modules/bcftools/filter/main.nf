// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process BCF_FILTER {
    tag "$sample_name - Segment:$segment - Ref Accession ID:$id"
    label 'process_medium'

    conda (params.enable_conda ? 'bioconda::bcftools=1.15.1' : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container 'https://depot.galaxyproject.org/singularity/run https://depot.galaxyproject.org/singularity/bcftools:1.15--haf5b3da_0'
    } else {
        container 'quay.io/biocontainers/bcftools:1.15--haf5b3da_0'
    }

    input:
    tuple val(sample_name), val(segment), val(id), path(fasta), path(depths), path(vcf)
    val (allele_fraction)

    output:
    tuple val(sample_name), val(segment), val(id), path(fasta),
    path(depths), path(filt_vcf), emit: vcf

    script:
    filt_vcf = "${sample_name}.Segment_${segment}.${id}.filt.vcf"
    """
    bcftools norm \\
        -Ov \\
        -m- \\
        -f $fasta \\
        $vcf \\
        > norm.vcf
    # filter for major alleles
    bcftools filter \\
        -e 'AF < $allele_fraction' \\
        norm.vcf \\
        -Ov \\
        -o $filt_vcf
    """
}
