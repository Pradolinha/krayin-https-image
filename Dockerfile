FROM webkul/krayin:2.1.5

WORKDIR /var/www/html/laravel-crm

# 1) Confiar no proxy (Traefik/Caddy) e aceitar X-Forwarded-* corretamente
RUN set -eux; \
  FILE="app/Http/Middleware/TrustProxies.php"; \
  if [ -f "$FILE" ]; then \
    sed -i 's/protected \$proxies.*/protected $proxies = "\\x2a";/g' "$FILE" || true; \
    sed -i 's/protected \$headers.*/protected $headers = Request::HEADER_X_FORWARDED_ALL;/g' "$FILE" || true; \
  fi

# 2) Forçar HTTPS dentro do Laravel pra zerar mixed-content e “formulário não seguro”
RUN php -r '
$f="app/Providers/AppServiceProvider.php";
$c=@file_get_contents($f);
if($c===false){fwrite(STDERR,"Arquivo não encontrado: $f\n"); exit(1);}

if(strpos($c,"use Illuminate\\\\Support\\\\Facades\\\\URL;")===false){
  $c=preg_replace("/namespace App\\\\\\\\Providers;\\s*/",
    "namespace App\\\\Providers;\\n\\nuse Illuminate\\\\Support\\\\Facades\\\\URL;\\n",
    $c, 1);
}

if(strpos($c,"URL::forceScheme")===false){
  $c=preg_replace("/public function boot\\(\\)\\s*\\{\\s*/",
    "public function boot()\\n    {\\n        if (env(\\x27FORCE_HTTPS\\x27, false) || config(\\x27app.env\\x27) === \\x27production\\x27) {\\n            URL::forceScheme(\\x27https\\x27);\\n        }\\n\\n",
    $c, 1);
}

file_put_contents($f,$c);
'

# 3) Limpa caches pra não ficar preso em config antiga (http)
RUN php artisan optimize:clear || true
