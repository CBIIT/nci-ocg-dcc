# variant_analysis config
{
    'data_types' => [qw(
        WGS
        WXS
    )],
    'data_level_dir_names' => [qw(
        L3
    )],
    'parse_files' => {
        'TARGET' => {
            'WT' => {
                'WXS' => {
                    'L3' => [
                        'target-wt-17pairs-somatic-v1.1.mafplus.xlsx',
                        'target-wt-17pairs-NCI-somatic-exonic.bcmmaf.txt',
                        'target-wt-primary-recurrent-NCI-somatic-exonic.bcmmaf.txt',
                        'target-wt-pilot-bcm-somatic-v4.0.mafplus.xlsx',
                        'target-wt-pilot-nci-somatic-v4.0.mafplus.xlsx',
                    ],
                },
            },
        },
    },
    # ver_data_file_types order is important (don't change)
    # 1) strelka vcfs
    # 2) mpileup vcfs
    # 3) mpileup mafs
    'ver_data_file_types' => [qw(
        tcs_strelka_snv_vcf
        tcs_strelka_indel_vcf
        tcs_tumor_snv_vcf
        tcs_normal_snv_vcf
        tcs_tumor_indel_vcf
        tcs_normal_indel_vcf
        tcs_tumor_snv_maf
        tcs_normal_snv_maf
        rna_tumor_snv_maf
        rna_normal_snv_maf
        rna_tumor_indel_vcf
        rna_normal_indel_vcf
    )],
    'count_ratio_format' => '%.9f',
    'maf_sep_char' => '|',
    'maf_config' => {
        'CGI' => {
            'blank_val' => '',
            'gene_symbol' => 'Hugo_Symbol',
            'tumor_barcode' => 'Tumor_Sample_Barcode',
            'norm_barcode' => 'Match_Normal_Sample_Barcode',
            'chr' => 'Chromosome',
            'pos' => 'Start_position',
            'end_pos' => 'End_position',
            'variant_type' => 'VariantType',
            'variant_class' => 'Variant_Classification',
            'ref_allele' => 'Reference_Allele',
            'tumor_allele_1' => 'Tumor_Seq_Allele1',
            'tumor_allele_2' => 'Tumor_Seq_Allele2',
            'ver_method' => 'Verification_Method',
            'ver_status' => 'Verification_Status',
            'ver_status_val' => 'Somatic',
            'ver_ref_allele' => 'Reference_Allele_VS',
            'ver_tumor_allele_1' => 'Tumor_Seq_Allele1_VS',
            'ver_tumor_allele_2' => 'Tumor_Seq_Allele2_VS',
            'ver_norm_allele_1' => 'Match_Norm_Allele1_VS',
            'ver_norm_allele_2' => 'Match_Norm_Allele2_VS',
            'ver_vcf_filter' => 'VCF_Filter_VS',
            'tumor_tot_count' => 'TumorTotalCount_VS',
            'tumor_ref_count' => 'TumorRefCount_VS',
            'tumor_var_count' => 'TumorVarCount_VS',
            'tumor_var_ratio' => 'TumorVarRatio_VS',
            'norm_tot_count' => 'NormalTotalCount_VS',
            'norm_ref_count' => 'NormalRefCount_VS',
            'norm_var_count' => 'NormalVarCount_VS',
            'norm_var_ratio' => 'NormalVarRatio_VS',
        },
        'BCM' => {
            'blank_val' => '.',
            'gene_symbol' => 'Hugo_Symbol',
            'tumor_barcode' => 'Tumor_Sample_Barcode',
            'norm_barcode' => 'Matched_Norm_Sample_Barcode',
            'chr' => 'Chromosome',
            'pos' => 'Start_position',
            'end_pos' => 'End_position',
            'variant_type' => 'Variant_Type',
            'variant_class' => 'Variant_Classification',
            'ref_allele' => 'Reference_Allele',
            'tumor_allele_1' => 'Tumor_Seq_Allele1',
            'tumor_allele_2' => 'Tumor_Seq_Allele2',
            'ver_method' => 'Validation_Method',
            'ver_status' => 'Verification_Status',
            'ver_status_val' => 'Valid',
            'val_status' => 'Validation_Status',
            'val_status_val' => 'Valid',
            'mut_status' => 'Mutation_Status',
            'mut_status_val' => 'Somatic',
            'ver_ref_allele' => 'Reference_Validation_Allele',
            'ver_tumor_allele_1' => 'Tumor_Validation_Allele1',
            'ver_tumor_allele_2' => 'Tumor_Validation_Allele2',
            'ver_norm_allele_1' => 'Match_Norm_Validation_Allele1',
            'ver_norm_allele_2' => 'Match_Norm_Validation_Allele2',
            'ver_vcf_filter' => 'Validation_VCF_Filter',
            'tumor_tot_count' => 'TTotCovVal',
            'tumor_ref_count' => 'TRefCovVal',
            'tumor_var_count' => 'TVarCovVal',
            'tumor_var_ratio' => 'TVarRatioVal',
            'norm_tot_count' => 'NTotCovVal',
            'norm_ref_count' => 'NRefCovVal',
            'norm_var_count' => 'NVarCovVal',
            'norm_var_ratio' => 'NVarRatioVal',
        },
        'BCCA' => {
            'blank_val' => '',
            'gene_symbol' => 'Gene Symbol',
            'tumor_barcode' => 'Tumor_Sample_Barcode',
            'norm_barcode' => 'Match_Norm_Sample_Barcode',
            'chr' => 'Chromosome',
            'pos' => 'Start_Position',
            'end_pos' => 'End_Position',
            'variant_type' => 'Variant_Type',
            'variant_class' => 'Transcript architecture around variant',
            'ref_allele' => 'Reference_Allele',
            'tumor_allele_1' => 'Tumor_Seq_Allele1',
            'tumor_allele_2' => 'Tumor_Seq_Allele2',
            'ver_method' => 'Verification_Method',
            'ver_status' => 'Verification_Status',
            'ver_status_val' => 'Somatic',
            'ver_ref_allele' => 'Reference_Allele_VS',
            'ver_tumor_allele_1' => 'Tumor_Seq_Allele1_VS',
            'ver_tumor_allele_2' => 'Tumor_Seq_Allele2_VS',
            'ver_norm_allele_1' => 'Match_Norm_Allele1_VS',
            'ver_norm_allele_2' => 'Match_Norm_Allele2_VS',
            'ver_vcf_filter' => 'VCF_Filter_VS',
            'tumor_tot_count' => 'TumorTotalCount_VS',
            'tumor_ref_count' => 'TumorRefCount_VS',
            'tumor_var_count' => 'TumorVarCount_VS',
            'tumor_var_ratio' => 'TumorVarRatio_VS',
            'norm_tot_count' => 'NormalTotalCount_VS',
            'norm_ref_count' => 'NormalRefCount_VS',
            'norm_var_count' => 'NormalVarCount_VS',
            'norm_var_ratio' => 'NormalVarRatio_VS',
        },
    },
}
