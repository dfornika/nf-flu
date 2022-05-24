// Import generic module functions
include { getSoftwareName } from './functions'

process MEDAKA{
    tag "$sample_name - Segment:$segment - Ref ID:$id"
    label 'process_low'

    conda (params.enable_conda ? 'bioconda::medaka=1.4.4' : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
      container 'https://depot.galaxyproject.org/singularity/medaka:1.4.4--py38h130def0_0'
    } else {
      container 'quay.io/biocontainers/medaka:1.4.4--py38h130def0_0'
    }

    input:
    tuple val(sample_name), val(segment), val(id), path(fasta), path(bam),
    path(depths)

    output:
    tuple val(sample_name), val(segment), val(id), path(fasta), path(depths), path(vcf), emit: vcf
    path (medaka_dir) , emit: output_dir
    path (medaka_log), emit: log
    path "versions.yml" , emit: versions

    script:
    def software  = getSoftwareName(task.process)
    vcf           = "${sample_name}.Segment_${segment}.${id}.medaka_variant.vcf"
    medaka_dir    = "${sample_name}.Segment_${segment}.${id}.medaka_variant/"
    medaka_log    = "${sample_name}.Segment_${segment}.${id}.medaka_variant.log"
    """
    medaka_variant \\
        -o ${medaka_dir} \\
        -t ${task.cpus} \\
        -f $fasta \\
        -i ${bam[0]} \\
        -m ${params.medaka_variant_model} \\
        -s ${params.medaka_snp_model}
    medaka tools annotate \\
        ${medaka_dir}/round_1.vcf \\
        $fasta \\
        ${bam[0]} \\
        ${vcf} \\
        --dpsp
    ln -s .command.log $medaka_log
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$(medaka --version 2>&1 | sed 's/^.*medaka //')
    END_VERSIONS
    """
}
