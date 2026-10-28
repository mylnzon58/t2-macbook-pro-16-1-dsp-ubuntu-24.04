# MacBook Pro 16,1 (2019, A2141) 6-Channel Speaker DSP Fix for Ubuntu 24.04 LTS (PipeWire 1.0.7)

[![Ubuntu 24.04 LTS](https://img.shields.io/badge/Ubuntu-24.04_LTS_(Noble)-E95420?logo=ubuntu&logoColor=white)](#)
[![PipeWire 1.0.7](https://img.shields.io/badge/PipeWire-1.0.7_(LV2_Enabled)-00B4D8?logo=linux&logoColor=white)](#)
[![Hardware](https://img.shields.io/badge/Apple_T2-MacBookPro16%2C1_(A2141)-111827?logo=apple&logoColor=white)](#)
[![Author](https://img.shields.io/badge/Author-mylnzon58_(mylnzon58%40gmail.com)-10B981?logo=github&logoColor=white)](https://github.com/mylnzon58)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **Author & Maintainer:** **[@mylnzon58](https://github.com/mylnzon58)** (`mylnzon58@gmail.com`)  
> Si esta solución reparó el sonido de tu MacBook Pro 16" en Ubuntu 24.04, **dale una estrella (Star) al repositorio y sígueme en GitHub ([@mylnzon58](https://github.com/mylnzon58))**.  
> If this fixed your MacBook Pro 16" audio on Ubuntu 24.04, **please Star this repo and Follow [@mylnzon58](https://github.com/mylnzon58) on GitHub**.

**[Español](#-español--solución-dsp-para-macbook-pro-161-en-ubuntu-2404-lts)** | **[English](#-english--macbook-pro-161-dsp-speaker-fix-for-ubuntu-2404-lts)**

---

## 🇪🇸 Español — Solución DSP para MacBook Pro 16,1 en Ubuntu 24.04 LTS

### El Problema (Al grano)

En el **MacBook Pro 16" 2019 (`MacBookPro16,1` / `A2141`)** con chip **Apple T2**, el sistema de sonido interno tiene **6 altavoces físicos** (4 woofers con cancelación de fuerza + 2 tweeters). Sin procesamiento DSP, suena plano, metálico y a bajo volumen.

Al intentar usar `t2-apple-audio-dsp` en **Ubuntu 24.04 LTS (Noble Numbat)**, todo falla por **4 causas técnicas combinadas**:

1. **PipeWire `1.0.5` oficial de Ubuntu 24.04 no tiene soporte LV2** (compilado con `-Dlv2=disabled`), provocando que PipeWire muera al iniciar con:
   ```text
   mod.filter-chain: can't load plugin type 'lv2': No existe el archivo o el directorio
   mod.filter-chain: can't load graph: No existe el archivo o el directorio
   pw.conf: could not load mandatory module "libpipewire-module-filter-chain": No existe el archivo o el directorio
   ```
2. **La rama `master` de `t2-apple-audio-dsp` no funciona en Ubuntu 24.04**: Fue reescrita para Ubuntu 25.10/26.04 usando **WirePlumber 0.5+** (`node.software-dsp`), mientras que Ubuntu 24.04 usa **WirePlumber 0.4.17** (scripts Lua).
3. **Confusión con `libspa-filter-graph-plugin-lv2.so`**: Ese archivo solo existe en PipeWire $\ge 1.2$. En **PipeWire 1.0.7** (desde `ppa:pipewire-debian/pipewire-upstream`), el binario LV2 real es `/usr/lib/x86_64-linux-gnu/pipewire-0.3/libpipewire-module-filter-chain-lv2.so`.
4. **Puertos LV2 rotos en la rama `speakers_161` con `calf-plugins 0.90.3` y `lsp-plugins-lv2 1.2.14`**:
   Al activar LV2 en PipeWire 1.0.7, el grafo original falla al aplicar controles:
   ```text
   mod.filter-chain: control 'meter_in' can not be set: No existe el archivo o el directorio
   mod.filter-chain: control 'meter_out' can not be set: No existe el archivo o el directorio
   mod.filter-chain: control 'clip_in' can not be set: No existe el archivo o el directorio
   mod.filter-chain: control 'clip_out' can not be set: No existe el archivo o el directorio
   mod.filter-chain: control 'bypass' can not be set: No existe el archivo o el directorio
   mod.filter-chain: control 'cbe_0' can not be set: No existe el archivo o el directorio
   ```
   - En **Calf BassEnhancer**, `meter_in`, `meter_out`, `clip_in` y `clip_out` son puertos de salida (`lv2:OutputPort`), no controles de entrada.
   - En **LSP Multiband Compressor Stereo x8 (`1.2.14`)**, el puerto `bypass` fue reemplazado por `enabled = 1`, y la banda base 0 no posee puerto `cbe_0` (solo `cbe_1..cbe_7`; la banda 0 se habilita con `ce_0 = 1`).

---

### La Solución (Parcheada por `mylnzon58`)

Este repositorio incluye el grafo DSP corregido ([`config/pipewire/10-t2_161_speakers.conf`](config/pipewire/10-t2_161_speakers.conf)), las respuestas impulsionales FIR de 44.1/48/96 kHz para el modelo `16,1`, el perfil ALSA de 6 canales (`apple-t2x6.conf`), las rutas de mezclador (`config/alsa-card-profile/paths/t2-*.conf`), la regla `udev` (`91-audio-custom.rules`) y el instalador automatizado:

- Corrige los descriptores LV2 para **Calf BassEnhancer** y **LSP Multiband Compressor 1.2.14**.
- Detecta automáticamente la dirección PCI del controlador Apple T2 (`106b:1803`) y desactiva cualquier archivo antiguo en `/etc/pipewire/pipewire.conf.d/10-t2_161_speakers.conf` para evitar conflictos.
- Añade `priority.session = 1500` en `capture.props` para que **MacBook Pro T2 DSP Speakers** se seleccione automáticamente como salida predeterminada.
- Ajusta automáticamente el sink físico de 6 canales (`Apple Audio Device Speakers`) al **100 % (0 dB)** para evitar doble atenuación antes del limitador LADSPA (`fastLookaheadLimiter`) y los 4 convolvers FIR.

> **Requisito base:** Tener instalado el kernel T2 Linux (`linux-t2`) en Ubuntu 24.04 LTS para que el dispositivo PCI de audio Apple T2 (`106b:1803`) sea reconocido por ALSA.

---

### Instalación Rápida (1 minuto)

```bash
git clone https://github.com/mylnzon58/t2-macbook-pro-16-1-dsp-ubuntu-24.04.git
cd t2-macbook-pro-16-1-dsp-ubuntu-24.04
chmod +x install.sh uninstall.sh
./install.sh
```

#### Verificación del grafo de 6 canales

Ejecuta `wpctl status` y confirma que `MacBook Pro T2 DSP Speakers` tiene el asterisco `*` y los 6 canales `AUX0..AUX5` están en `[active]`:

```text
 ├─ Sinks:
 │  *   39. MacBook Pro T2 DSP Speakers         [vol: 0.70]
 │      64. Apple Audio Device Speakers         [vol: 1.00]
 └─ Streams:
        40. effect_output.filter-chain-speakers
             53. output_AUX0     > Speaker:playback_FL  [active]
             54. output_AUX1     > Speaker:playback_SL  [active]
             55. output_AUX2     > Speaker:playback_RL  [active]
             56. output_AUX3     > Speaker:playback_FR  [active]
             57. output_AUX4     > Speaker:playback_SR  [active]
             58. output_AUX5     > Speaker:playback_RR  [active]
```

---

## 🇬🇧 English — MacBook Pro 16,1 DSP Speaker Fix for Ubuntu 24.04 LTS

### The Problem (Straight to the point)

The **2019 16-inch MacBook Pro (`MacBookPro16,1` / `A2141`)** uses an **Apple T2** audio controller driving **6 discrete speaker channels** (`LW1`, `LW2`, `LT`, `RW1`, `RW2`, `RT`). Without a 6-channel FIR convolver + multiband DSP chain, the internal speakers sound tinny and quiet on Linux.

On **Ubuntu 24.04 LTS (Noble Numbat)**, existing `t2-apple-audio-dsp` setups fail due to **4 overlapping issues**:

1. **Ubuntu 24.04 stock `pipewire 1.0.5` lacks LV2 support** (`-Dlv2=disabled`, Launchpad Bug #2054223), crashing PipeWire on startup with:
   ```text
   mod.filter-chain: can't load plugin type 'lv2': No such file or directory
   mod.filter-chain: can't load graph: No such file or directory
   pw.conf: could not load mandatory module "libpipewire-module-filter-chain": No such file or directory
   ```
2. **`t2-apple-audio-dsp` `master` branch targets Ubuntu 25.10/26.04 (WirePlumber 0.5+)**: It relies on `node.software-dsp` rules that do not exist in Ubuntu 24.04's **WirePlumber 0.4.17**.
3. **`libspa-filter-graph-plugin-lv2.so` vs PipeWire 1.0.7**: `libspa-filter-graph-plugin-lv2.so` only exists in PipeWire $\ge 1.2$. When upgrading Ubuntu 24.04 via `ppa:pipewire-debian/pipewire-upstream` to **PipeWire `1.0.7-3~ubuntu24.04`**, the LV2 module is actually `/usr/lib/x86_64-linux-gnu/pipewire-0.3/libpipewire-module-filter-chain-lv2.so`.
4. **Incompatible LV2 control ports in `speakers_161` branch**:
   With `calf-plugins 0.90.3` and `lsp-plugins-lv2 1.2.14` on Ubuntu 24.04, `10-t2_161_speakers.conf` fails to set 6 ports:
   - `meter_in`, `meter_out`, `clip_in`, `clip_out` in `http://calf.sourceforge.net/plugins/BassEnhancer` are read-only `lv2:OutputPort` ports.
   - In `http://lsp-plug.in/plugins/lv2/mb_compressor_stereo` (`1.2.14`), `bypass = 0` must be `enabled = 1`, and Band 0 has no `cbe_0` port (enabled via `ce_0 = 1`).

---

### The Solution (Engineered by `mylnzon58`)

1. **Upgrade PipeWire to `1.0.7` with LV2 enabled** (`ppa:pipewire-debian/pipewire-upstream`).
2. **Apply the patched [`10-t2_161_speakers.conf`](config/pipewire/10-t2_161_speakers.conf)**:
   ```diff
   @@ -21,10 +21,10 @@
                            level_in = 1.0
                            level_out = 1.0
                            amount = 0.9
   -                        meter_in = 0
   -                        meter_out = 0
   -                        clip_in = 0
   -                        clip_out = 0
   +                        #meter_in = 0
   +                        #meter_out = 0
   +                        #clip_in = 0
   +                        #clip_out = 0
   @@ -40,7 +40,7 @@
                            control = {
                                # Enable
                                mode = 1
   -                            bypass = 0
   +                            enabled = 1
   @@ -56,7 +56,7 @@
                                # Band 0
   -                            cbe_0 = 1
   +                            #cbe_0 = 1
                                ce_0 = 1
   @@ -231,6 +231,7 @@
                    media.class = Audio/Sink
                    audio.channels = 2
                    audio.position = [ FL FR ]
   +                priority.session = 1500
                }
   ```
3. **Calibrate hardware sink level**: Sets `Apple Audio Device Speakers` (`alsa_output.pci-0000_04_00.3.Speakers`) to `100%` (`1.00`) and selects `MacBook Pro T2 DSP Speakers` (`effect_input.filter-chain-speakers`) as default sink.

---

### Quick Install

```bash
git clone https://github.com/mylnzon58/t2-macbook-pro-16-1-dsp-ubuntu-24.04.git
cd t2-macbook-pro-16-1-dsp-ubuntu-24.04
./install.sh
```

To revert to stock raw audio at any time:
```bash
./uninstall.sh
```

---

### Créditos y Autoría / Credits & Authorship

- **Investigación de puertos LV2, parche para Ubuntu 24.04 LTS & PipeWire 1.0.7, automatización y documentación:**  
  **[@mylnzon58](https://github.com/mylnzon58)** — Contacto: `mylnzon58@gmail.com`
- **Respuestas impulsionales FIR originales (`macbook_pro_t2_16_1_*.wav`) y topología base T2:**  
  Proyecto comunitario [T2 Linux](https://t2linux.org) / `lemmyg/t2-apple-audio-dsp` (Licencia MIT).

---

### Indexación y Palabras Clave / SEO Keywords

`MacBookPro16,1 Ubuntu 24.04 audio fix`, `MacBook Pro 16 2019 A2141 speakers Linux DSP`, `t2-apple-audio-dsp Ubuntu 24.04 Noble`, `mod.filter-chain: can't load plugin type 'lv2'`, `libspa-filter-graph-plugin-lv2.so Ubuntu 24.04`, `libpipewire-module-filter-chain-lv2.so PipeWire 1.0.7`, `mod.filter-chain: control 'bypass' can not be set`, `mod.filter-chain: control 'cbe_0' can not be set`, `mod.filter-chain: control 'meter_in' can not be set`, `reparar parlantes MacBook Pro 16 2019 Ubuntu 24.04`, `sonido bajo MacBook Pro T2 Linux Ubuntu 24.04`, `Apple T2 6 channel speakers PipeWire filter-chain Calf BassEnhancer LSP mb_compressor_stereo`.
