# Shelltoys

Small shell utilities and desktop toys.

## MOTD installer

`install-motd.sh` installs a dynamic terminal login message for the common
Linux distro families:

- Ubuntu
- Debian
- Fedora/RHEL-family systems
- Arch-family systems

It also falls back cleanly on openSUSE/SLES and unknown distributions.

```bash
sudo ./install-motd.sh install
sudo ./install-motd.sh uninstall
./install-motd.sh print
```

## BMI calculators

### `toy-bmi-calculator.sh`

Simple YAD-based BMI calculator. It prompts for weight in kilograms and height
in centimeters, calculates BMI with `bc`, and shows the result with a basic
interpretation.

Dependencies:

- `bash`
- `yad`
- `bc`
- `sudo`, only if the script needs to install missing packages

The script can auto-install `yad` and `bc` on Debian/Ubuntu systems with
`apt-get`, or Red Hat-family systems with `yum`.

```bash
chmod +x ./toy-bmi-calculator.sh
./toy-bmi-calculator.sh
```

### `toy-bmi-calculator-gtk.sh`

RTD-integrated YAD BMI calculator. It provides the same BMI workflow as
`toy-bmi-calculator.sh`, but uses the RTD helper library `_rtd_library` for
dependency detection and package installation.

The script searches for `_rtd_library` locally in nearby `core` directories and
under `/opt`. If it cannot find the library locally, it tries to load it from
the RTD-Setup GitHub repository.

Dependencies:

- `bash`
- `_rtd_library`
- `yad`
- `bc`
- `curl` or `wget`, if `_rtd_library` must be fetched remotely

```bash
chmod +x ./toy-bmi-calculator-gtk.sh
./toy-bmi-calculator-gtk.sh
```
