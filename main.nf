#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { fastp } from './modules/species_abundance.nf'
include { fastp_json_to_csv } from './modules/species_abundance.nf'
include { kraken2 } from './modules/species_abundance.nf'
include { bracken } from './modules/species_abundance.nf'
include { abundance_top_5 } from './modules/species_abundance.nf'

workflow {
  ch_fastq = Channel.fromFilePairs( "${params.fastq_input}/*_R{1,2}*.fastq.gz", type: 'file', maxDepth: 1)
  ch_kraken_db = Channel.fromPath( "${params.kraken_db}", type: 'dir')
  ch_bracken_db = Channel.fromPath( "${params.bracken_db}", type: 'dir')

  main:
  fastp(ch_fastq)
  fastp_json_to_csv(fastp.out.fastp_json).map{ it -> it[1] }.collectFile(name:'read_qc.csv', keepHeader: true, sort: { it.text }, storeDir: "${params.outdir}")
  kraken2(fastp.out.reads.combine(ch_kraken_db))
  bracken(kraken2.out.combine(ch_bracken_db))
  abundance_top_5(bracken.out).map{ it -> it[1] }.collectFile(name:'abundances.csv', keepHeader: true, sort: { it.text }, storeDir: "${params.outdir}")
}
