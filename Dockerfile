FROM webkul/krayin:2.1.5

USER root
WORKDIR /var/www/html/laravel-crm

# Copia entrypoint que aplica permissões + caches no start (sem mexer no runtime do container)
COPY docker/entrypoint.sh /usr/local/bin/krayin-entrypoint
RUN chmod +x /usr/local/bin/krayin-entrypoint

# Patch: força o Laravel a gerar URLs em https quando FORCE_HTTPS=true
# (resolve blocked:mixed-content e “formulário não seguro”)
RUN set -eux; \
  FILE="app/Providers/AppServiceProvider.php"; \
  test -f "$FILE"; \
  \
  # garante import do URL
  if ! grep -q "use Illuminate\\\\Support\\\\Facades\\\\URL;" "$FILE"; then \
    sed -i '/^namespace App\\\\Providers;/a\
\
use Illuminate\\Support\\Facades\\URL;\
' "$FILE"; \
  fi; \
  \
  # injeta o forceScheme no boot (só se ainda não existir)
  if ! grep -q "URL::forceScheme('https')" "$FILE"; then \
    perl -0777 -i -pe "s/public function boot\\(\\)\\s*\\{\\s*/public function boot()\\n    {\\n        if (env('FORCE_HTTPS', false)) {\\n            URL::forceScheme('https');\\n        }\\n\\n/s" "$FILE"; \
  fi

# Healthcheck simples
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=5 \
  CMD curl -fsS http://127.0.0.1/admin/login >/dev/null || exit 1

# Mantém o CMD/entrypoint do container base, mas roda nosso hook antes
ENTRYPOINT ["/usr/local/bin/krayin-entrypoint"]
CMD ["supervisord", "-n"]
