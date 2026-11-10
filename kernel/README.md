# Kernel

Release v1 (2026-11-10) runs mainline Linux **7.1.13**, the same build as the Ubuntu Lomiri port (classic):

- `config-7.1.13` — kernel config;
- `patches/` — the m52xq changes on top of the device kernel tree: in-place call device switch (q6voice), panel sleep while the
  brightness is 0, ath11k power save with the radio off.

Binaries (`boot.img`, `vendor_boot.img`, `dtbo-frag.img`, `Image`, `modules-7.1.13.tar.gz`, `SHA256SUMS`): release
[kernel-7.1.13](https://github.com/korryasdlerto-lgtm/samsung-m52xq-ubuntu-lomiri/releases/tag/kernel-7.1.13) of samsung-m52xq-ubuntu-lomiri.
The images in the v1 zip (`firmware/`) are byte-identical to `boot.img`, `vendor_boot.img` and `dtbo-frag.img` of that release
(sha256 2b5962c1…, 53965b55…, c9114568…). At install time the IPA firmware of the phone is added to the boot ramdisk.

Source: https://github.com/korryasdlerto-lgtm/sc7280-mainline-linux-m52xq

Older: `config-7.1.2-430` and release kernel-7.1.2-430 of this repository (archives v2–v5).
