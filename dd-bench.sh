#!/usr/bin/env bash

#
# Dd-bench uses dd with various linux devices to benchmark storage io.
# Copyright (C) 2015  Aaron Ball <nullspoon@iohq.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#


#
# A simple logging function. Prints a pre-defined timestamped and formatted log
# entry.
#
# @param msg The log message
#
function log {
  msg=${1}
  ts=$(date '+%h %d %H:%M:%S')
  echo -e "${ts}: ${1}"
}


#
# Performs a read test, reading from the specified file and writing to
# /dev/null to avoid as many bottlenecks as possible
#
# @param dest  Path to read data from
# @param bs    Block size
# @param count Number of blocks to write
#
function read_bench {
  src="${1}"
  bs="${2}"
  count="${3}"

  dest="/dev/zero"

  out=$(dd if=${src} of=${dest} iflag=direct bs=${bs} count=${count} 2>&1 | grep -v records)
  # Parse out total data
  total=$(echo ${out} | sed 's/.*(\(.*B\)).*/\1/')
  speed=$(echo ${out} | sed 's/.*, \(.*B\/s\)/\1/')

  log "Read ${bs} ${count} times. ${total} read at ${speed}."
}


#
# Performs a write test, reading from /dev/zero to avoid any problems with cpu
# bottlenecks.
#
# @param dest  Path to write the temp file (be sure you have enough space)
# @param bs    Block size
# @param count Number of blocks to write
#
function write_bench {
  dest="${1}"
  bs="${2}"
  count="${3}"

  src="/dev/zero"

  out=$(dd if=${src} of=${dest} oflag=direct bs=${bs} count=${count} 2>&1 | grep -v records)
  # Parse out total data
  total=$(echo ${out} | sed 's/.*(\(.*B\)).*/\1/')
  speed=$(echo ${out} | sed 's/.*, \(.*B\/s\)/\1/')

  log "Wrote ${bs} ${count} times. ${total} written at ${speed}."
}


function main {
  if [[ -z "${1}" ]]; then
    echo "Please specify the path to a file to write tests to."
    echo "Note that this will overwrite that file, so one that doesn't exist is"
    echo "preferable."
    exit 1
  fi

  # Warn the user
  echo "This script will write up to 20 GB of data before it's done"
  echo "benchmarking. Be sure you have that much storage to spare on the disk"
  echo -e "being benchmarked.\n"
  wait=5
  echo -e "Proceeding with benchmark in ${wait} seconds...\n\n"
  sleep ${wait}

  echo -e "Benchmark started at $(date)\n"

  path="${1}"

  # Perform benchmark tests

  # Note that the 1KB block tests write 10 and 80 megabyte files rather than
  # the previous 1G, 8G, etc due to the speed of the typical 1KB block size
  # test. Also note that the 200 MB test is skipped because it takes far too
  # long.
  log "*** Testing 1 KB blocks"
  write_bench "${path}" "1K" "10240"
  read_bench  "${path}" "1K" "10240"
  write_bench "${path}" "1K" "81920"
  read_bench  "${path}" "1K" "81920"

  log "*** Testing 1 MB blocks"
  write_bench "${path}" "1M" "1024"
  read_bench  "${path}" "1M" "1024"
  write_bench "${path}" "1M" "8192"
  read_bench  "${path}" "1M" "8192"
  write_bench "${path}" "1M" "20480"
  read_bench  "${path}" "1M" "20480"

  log "*** Testing 2 MB blocks"
  write_bench "${path}" "2M" "512"
  read_bench  "${path}" "2M" "512"
  write_bench "${path}" "2M" "4096"
  read_bench  "${path}" "2M" "4096"
  write_bench "${path}" "2M" "10240"
  read_bench  "${path}" "2M" "10240"

  log "*** Testing 4 MB blocks"
  write_bench "${path}" "4M" "256"
  read_bench  "${path}" "4M" "256"
  write_bench "${path}" "4M" "2048"
  read_bench  "${path}" "4M" "2048"
  write_bench "${path}" "4M" "5120"
  read_bench  "${path}" "4M" "5120"

  log "*** Testing 1 GB blocks"
  write_bench "${path}" "1G" "1"
  read_bench  "${path}" "1G" "1"
  write_bench "${path}" "1G" "8"
  read_bench  "${path}" "1G" "8"
  write_bench "${path}" "1G" "20"
  read_bench  "${path}" "1G" "20"

  # Attempt cleanup only if the destination test path is a file and not a
  # device (no sense in trying to remove a device).
  if [[ -f "${path}" ]]; then
    rm "${path}"
  fi
}

main ${@}
