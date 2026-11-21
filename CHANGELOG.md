# Changelog

Breaking changes are listed first in each entry. Read the entry before you apply an update on Railway, and back up your MySQL volume first.

## 10.1.4 (2026-11-21)

- No breaking changes. Records, users and settings in MySQL and files in `data/`, `custom/` and `client/custom/` on the volume are kept; the image runs EspoCRM's own upgrade step at start. Back up your MySQL volume first, as for every update.
- EspoCRM [10.1.4](https://github.com/espocrm/espocrm/releases/tag/10.1.4): fixes import of URL-multiple fields with non-ASCII characters.
- Image: `espocrm/espocrm:10.1.4-apache@sha256:5f8fa9a708893b9fbfe55a778f24c952a6a73b94c97fb126eccd21aa936c878c`.

## 10.1.3 (2026-11-19)

- First release of this template.
- EspoCRM 10.1.3, official image `espocrm/espocrm:10.1.3-apache@sha256:1d6f5eab228e163f63e9195370b6c4dc1b9f6b7cc508521507a22eca42fd8d22`.
- One EspoCRM service runs the web app, the job daemon and the WebSocket server (proxied on `/wss`); `data/`, `custom/` and `client/custom/` live on the volume at `/espocrm-storage`.
- Railway MySQL as the database.
- Deploy on Railway button added to the README.
