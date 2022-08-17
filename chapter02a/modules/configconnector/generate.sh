#!/bin/env bash

set -euo pipefail

TMP_DIR="/tmp/configconnector"
DST_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VERSION="1.91.0"

gsutil cp "gs://configconnector-operator/${VERSION}/release-bundle.tar.gz" "${TMP_DIR}/bundle.tar.gz"
tar zxvf "${TMP_DIR}/bundle.tar.gz" -C "${TMP_DIR}"
cp "${TMP_DIR}/operator-system/configconnector-operator.yaml" "${DST_DIR}/generated.yaml"



