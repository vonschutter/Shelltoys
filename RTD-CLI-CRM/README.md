# RTD CLI CRM

`rtd-crm` is a small text-file CRM for customers, opportunities, opportunity stages, opportunity details, and communication logs.

## Storage

By default, data is stored in:

```text
${XDG_DATA_HOME:-$HOME/.local/share}/rtd-crm
```

You can override this per command:

```bash
rtd-crm --dir /path/to/crm-data customer list
```

Or for a shell session:

```bash
export RTD_CRM_DIR=/path/to/crm-data
```

Records are plain text:

```text
customers/<customer-id>.customer
opportunities/<opportunity-id>.opportunity
```

Each file uses simple `key: value` metadata followed by free-text sections such as `## Notes`, `## Detail`, and `## Communication Log`.

## Quick Start

```bash
./rtd-crm init

./rtd-crm customer add \
  --name "Acme AB" \
  --company "Acme" \
  --email sales@example.com \
  --phone "+46 8 123 456" \
  --notes "Initial contact from conference."

./rtd-crm opportunity add \
  --customer acme-ab \
  --title "Support agreement" \
  --value 25000 \
  --stage proposal \
  --probability 60 \
  --close-date 2026-05-31 \
  --detail "Annual support agreement."
```

## Common Commands

```bash
./rtd-crm customer list
./rtd-crm customer show acme-ab
./rtd-crm customer edit acme-ab

./rtd-crm opportunity list --sort value --reverse
./rtd-crm opportunity list --sort stage
./rtd-crm opportunity list --stage proposal
./rtd-crm opportunity stage support-agreement won
./rtd-crm opportunity edit support-agreement
```

## Text UI

The CRM includes a `dialog`-based terminal UI:

```bash
./rtd-crm ui
```

The UI supports:

```text
Customers: add, list, view, edit, add communication log, add opportunity
Opportunities: add, list/sort, view, edit, change stage, add communication log
Logs: add one communication log to a customer and optionally an opportunity
```

Install `dialog` if it is not already available:

```bash
sudo apt install dialog
sudo dnf install dialog
sudo zypper install dialog
```

## Communication Logs

Add a customer log entry:

```bash
./rtd-crm customer log acme-ab \
  --type call \
  --summary "Discussed renewal" \
  --detail "Customer wants a revised offer next week."
```

Add one log entry to both the customer and opportunity files:

```bash
./rtd-crm log add \
  --customer acme-ab \
  --opportunity support-agreement \
  --type email \
  --summary "Sent revised proposal"
```

## Editing

The app uses `$EDITOR`, then `nano`, then `vi`.

```bash
EDITOR=vim ./rtd-crm customer edit acme-ab
EDITOR=vim ./rtd-crm opportunity edit support-agreement
```
