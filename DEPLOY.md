# Ubuntu VPS üzerinde yayınlama

Bu site Docker içindeki Caddy ile yayınlanır. Caddy'yi Ubuntu'ya ayrıca kurmanız gerekmez.

## 1. Docker ve Compose kurun

Ubuntu için Docker'ın [resmî apt kurulumu](https://docs.docker.com/engine/install/ubuntu/):

```sh
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker run hello-world
sudo docker compose version
```

Docker ve Compose zaten kuruluysa bu kurulum adımını tekrar çalıştırmayın. `apt update` sırasında `Conflicting values set for option Signed-By` hatası çıkarsa aynı Docker deposu iki farklı kaynak dosyasında tanımlıdır. Kayıtları görmek için:

```sh
sudo grep -RInE 'download\.docker\.com/linux/ubuntu|docker-archive-keyring\.gpg' /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null
```

`docker.sources` güncel kayıt olarak kalmalıdır. Eski anahtarı (`/usr/share/keyrings/docker-archive-keyring.gpg`) kullanan ikinci kayıt `/etc/apt/sources.list.d/docker.list` içindeyse:

```sh
sudo mv /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/docker.list.disabled
sudo apt update
```

Eski kayıt başka dosyadaysa yalnızca o Docker kaydını devre dışı bırakın; başka depoların kayıtlarını değiştirmeyin.

## 2. Alan adını ve portları hazırlayın

Hostinger DNS panelinde `enybeauty.com` için `@` adlı A kaydını `45.131.1.31` adresine yönlendirin. Eski sunucuya giden diğer `@` A kayıtlarını silin. VPS için IPv6 yapılandırmadıysanız eski `@` AAAA kayıtlarını da silin. `www` için eski CDN kaydını kaldırıp `@` alan adına bir CNAME oluşturun; Caddy `www.enybeauty.com` isteklerini ana alan adına yönlendirir. Hostinger CDN açıksa önce devre dışı bırakın. E-posta için kullanılan MX/TXT kayıtlarına dokunmayın.

DNS değişiklikleri yayılana kadar bekleyin; bunu `dig +short A enybeauty.com` ve `dig +short A www.enybeauty.com` komutlarıyla kontrol edebilirsiniz. Her ikisi de `45.131.1.31` adresine çözülmelidir. `dig +short AAAA enybeauty.com` eski sunucunun IPv6 adreslerini döndürmemelidir. VPS sağlayıcısının güvenlik duvarında ve Ubuntu'da 80/TCP ile 443/TCP portlarını açın; SSH erişimini de açık tutun. Bu portlarda çalışan başka bir web sunucusu varsa önce çakışmayı giderin.

## 3. Siteyi başlatın

Önce Mac'teki proje dizininde yeni Docker dosyalarını GitHub'a gönderin:

```sh
git add .dockerignore Caddyfile DEPLOY.md Dockerfile compose.yaml
git commit -m "Add Docker and Caddy deployment"
git push origin main
```

Ardından VPS'te:

```sh
git clone https://github.com/berkesongul/enybeauty.git /opt/enybeauty
cd /opt/enybeauty
```

DNS yönlendirmesi tamamlandıktan sonra:

```sh
sudo docker compose config
sudo docker compose up --build -d
sudo docker compose ps
sudo docker compose logs --tail=100 web
```

Tarayıcıda `https://enybeauty.com` ve `https://www.enybeauty.com` adreslerini açın. Caddy, uygun DNS ve açık portlarla HTTPS sertifikalarını otomatik alır ve yeniler. Sertifikalar `caddy_data` volume'unda kalır; bu volume'u rutin güncellemelerde silmeyin.

## Güncelleme

Mac'te değişiklikleri GitHub'a gönderdikten sonra VPS'te:

```sh
git pull --ff-only
sudo docker compose up --build -d
```

Site açılmıyorsa DNS kaydını, port 80/443 erişimini ve `sudo docker compose logs web` çıktısını kontrol edin.
