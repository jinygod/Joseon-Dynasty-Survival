/// Machine-readable release gates for visual asset provenance.
abstract final class AssetRightsPolicy {
  static const acquisitionMethods = <String>{
    'self_made',
    'ai_generated',
    'purchased',
    'commissioned',
    'open_asset',
  };

  static const statuses = <String>{
    'draft',
    'review',
    'approved',
    'blocked',
    'retired',
  };

  static const ledgerColumns = <String>[
    'asset_id',
    'runtime_path',
    'category',
    'acquisition_method',
    'creator_or_vendor',
    'provider_product_model',
    'created_or_purchased_at',
    'source_url',
    'terms_or_license_name',
    'terms_checked_at',
    'evidence_path',
    'source_file_sha256',
    'prompt_path',
    'input_rights_confirmed',
    'human_edits',
    'similarity_reviewed',
    'trademark_reviewed',
    'credit_required',
    'credit_text',
    'status',
    'reviewer',
    'reviewed_at',
    'notes',
  ];

  static bool canShip(String status) => status == 'approved';
}
