/**
 * Compresse les images admin avant envoi (contourne la limite Nginx ~1 Mo).
 * Cible : ~900 Ko max, JPEG, largeur max 1920 px.
 */
(function () {
    const MAX_BYTES = 900 * 1024;
    const MAX_WIDTH = 1920;
    const JPEG_QUALITY = 0.82;

    async function compressImageFile(file) {
        if (!file.type || !file.type.startsWith('image/')) {
            return file;
        }
        if (file.size <= MAX_BYTES) {
            return file;
        }

        const bitmap = await createImageBitmap(file);
        let width = bitmap.width;
        let height = bitmap.height;

        if (width > MAX_WIDTH) {
            height = Math.round((height * MAX_WIDTH) / width);
            width = MAX_WIDTH;
        }

        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(bitmap, 0, 0, width, height);
        bitmap.close();

        let quality = JPEG_QUALITY;
        let blob = await canvasToBlob(canvas, quality);

        while (blob && blob.size > MAX_BYTES && quality > 0.45) {
            quality -= 0.08;
            blob = await canvasToBlob(canvas, quality);
        }

        if (!blob || blob.size >= file.size) {
            return file;
        }

        const baseName = file.name.replace(/\.[^.]+$/, '') || 'image';
        return new File([blob], baseName + '.jpg', { type: 'image/jpeg', lastModified: Date.now() });
    }

    function canvasToBlob(canvas, quality) {
        return new Promise(function (resolve) {
            canvas.toBlob(resolve, 'image/jpeg', quality);
        });
    }

    window.AdminImageUpload = {
        attach: function (options) {
            const form = document.querySelector(options.form);
            const input = document.querySelector(options.input);
            if (!form || !input) {
                return;
            }

            form.addEventListener('submit', async function (e) {
                if (form.dataset.imageCompressed === '1') {
                    return;
                }
                if (!input.files || input.files.length === 0) {
                    return;
                }

                const oversized = Array.from(input.files).some(function (f) {
                    return f.size > MAX_BYTES;
                });
                if (!oversized) {
                    return;
                }

                e.preventDefault();

                const statusEl = options.statusSelector
                    ? document.querySelector(options.statusSelector)
                    : null;
                if (statusEl) {
                    statusEl.textContent = 'Compression des images en cours…';
                }

                try {
                    const dt = new DataTransfer();
                    for (const file of input.files) {
                        dt.items.add(await compressImageFile(file));
                    }
                    input.files = dt.files;
                    form.dataset.imageCompressed = '1';
                    form.submit();
                } catch (err) {
                    console.error('Compression image:', err);
                    if (statusEl) {
                        statusEl.textContent = '';
                    }
                    alert('Impossible de compresser l\'image. Utilisez une image plus légère (< 1 Mo) ou l\'admin en IP directe.');
                }
            });
        }
    };
})();
