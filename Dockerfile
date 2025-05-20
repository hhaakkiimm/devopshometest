# Gunakan image PHP-FPM sebagai base image untuk menjalankan PHP
FROM php:8.2-fpm

# Set working directory di dalam container
WORKDIR /var/www/html

# Instal dependensi sistem yang dibutuhkan oleh Laravel
# Perintah ini digabung untuk efisiensi layer Docker
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    # Membersihkan cache apt untuk mengurangi ukuran image
    && rm -rf /var/lib/apt/lists/*

# Instal ekstensi PHP yang dibutuhkan oleh Laravel
# Gunakan docker-php-ext-install untuk menginstal ekstensi PHP
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Salin composer.json dan composer.lock untuk menginstal dependensi
# Melakukannya sebelum COPY . . memanfaatkan Docker caching
COPY composer.json composer.lock ./

# Instal Composer global
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Jalankan Composer install untuk menginstal dependensi PHP
# --no-dev untuk produksi, --optimize-autoloader untuk performa, --no-scripts agar lebih stabil saat build
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Salin seluruh isi proyek ke dalam container
COPY . .

# Penting: Set permissions untuk storage dan bootstrap/cache agar bisa ditulis
# Ini harus dilakukan SETELAH 'COPY . .' dan SEBELUM perintah Artisan yang menulis file
RUN chown -R www-data:www-data storage bootstrap/cache
RUN chmod -R 775 storage bootstrap/cache

# Jalankan perintah Artisan untuk optimasi dan setup
# APP_KEY dibutuhkan, maka generate dulu
RUN php artisan key:generate
RUN php artisan optimize:clear
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache

# Expose port 9000 untuk PHP-FPM (ini adalah port yang digunakan PHP-FPM)
EXPOSE 9000

# Perintah yang akan dijalankan saat container dimulai (menjalankan PHP-FPM)
CMD ["php-fpm"]