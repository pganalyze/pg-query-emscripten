#!/usr/bin/env bash

set -e

LIB_PG_QUERY_TAG="13-2.0.4"

# Exported variables are required in `Makefile`
export BUILD_DIR=tmp/${LIB_PG_QUERY_TAG}
export FLATTENED_LIB_DIR="${BUILD_DIR}/flattened"
export OBJECT_DIR="${BUILD_DIR}/object"

LIB_DIR="${BUILD_DIR}/libpg_query"
LIB_ARCHIVE="${BUILD_DIR}/libpg_query.tar.gz"

# Change working directory to script directory
cd "${0%/*}"

mkdir -p "${BUILD_DIR}"

if [ ! -e "${LIB_ARCHIVE}" ]; then
	curl -o "${LIB_ARCHIVE}" \
		"https://codeload.github.com/lfittl/libpg_query/tar.gz/${LIB_PG_QUERY_TAG}"
fi

rm -rf "${LIB_DIR}"
mkdir "${LIB_DIR}"

tar -xf "${LIB_ARCHIVE}" -C "${LIB_DIR}" --strip-components 1

rm -rf "${FLATTENED_LIB_DIR}"
mkdir -p "${FLATTENED_LIB_DIR}"

cp -a ${LIB_DIR}/src/* "${FLATTENED_LIB_DIR}"
mv ${FLATTENED_LIB_DIR}/postgres/* "${FLATTENED_LIB_DIR}"
rm -r "${FLATTENED_LIB_DIR}/postgres"
cp -a "${LIB_DIR}/pg_query.h" "${FLATTENED_LIB_DIR}/include"

# Vendored dependencies
if [ -d "${LIB_DIR}/protobuf" ]; then
	cp -a "${LIB_DIR}/protobuf" "${FLATTENED_LIB_DIR}/include/"
	cp -a ${LIB_DIR}/protobuf/* "${FLATTENED_LIB_DIR}/"
fi

if [ -d "${LIB_DIR}/vendor/protobuf-c" ]; then
	cp -a "${LIB_DIR}/vendor/protobuf-c" "${FLATTENED_LIB_DIR}/include/"
	cp -a ${LIB_DIR}/vendor/protobuf-c/* "${FLATTENED_LIB_DIR}/"
fi

if [ -d "${LIB_DIR}/vendor/xxhash" ]; then
	cp -a "${LIB_DIR}/vendor/xxhash" "${FLATTENED_LIB_DIR}/include/"
	cp -a ${LIB_DIR}/vendor/xxhash/* "${FLATTENED_LIB_DIR}/"
fi

# Make every `.c` file in the top-level directory into its own translation unit
mv ${FLATTENED_LIB_DIR}/*_conds.c ${FLATTENED_LIB_DIR}/*_defs.c ${FLATTENED_LIB_DIR}/*_helper.c ${FLATTENED_LIB_DIR}/*_random.c ${FLATTENED_LIB_DIR}/include

echo "#undef HAVE_SIGSETJMP" >> "${FLATTENED_LIB_DIR}/include/pg_config.h"
echo "#undef HAVE_SPINLOCKS" >> "${FLATTENED_LIB_DIR}/include/pg_config.h"
echo "#undef PG_INT128_TYPE" >> "${FLATTENED_LIB_DIR}/include/pg_config.h"

make -j $(nproc) "${1}"
