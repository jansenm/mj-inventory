# SPDX-FileCopyrightText: 2021 Michael Jansen <info@michael-jansen.biz>
# SPDX-License-Identifier: CC0-1.0
ifndef VERBOSE
.SILENT:
endif

test: reclass

reclass: reclass-compatibility

reclass-%:
	reclass -o json --inventory -b ./test/data/reclass-$* > ./test/data/reclass-$*/reclass.json