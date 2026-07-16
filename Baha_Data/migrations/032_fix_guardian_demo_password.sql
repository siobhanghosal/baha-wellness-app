update users
set
  metadata = jsonb_set(
    coalesce(metadata, '{}'::jsonb),
    '{dev_auth}',
    '{
      "mode": "id_password",
      "salt_b64": "YmFoYS1kZW1vLXN0dWRlbnQtMDAx",
      "password_hash_b64": "4EyIOU6AEtSRBB0wdSKBgzDpS6Xg0570JAZyEuidTlk=",
      "iterations": 200000
    }'::jsonb,
    true
  ),
  updated_at = now()
where external_auth_id = 'supabase-guardian-demo';
