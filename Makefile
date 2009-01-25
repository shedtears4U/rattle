# TARGETS
#
# local:	Build and install into the local machine's R archive
# check:	Ask R to check that the package looks okay
# html:		Build the HTML documents and view in a browser
# install:	Build and copy the package across to the public www
# access:	Have a look at who might be downloading rattle

PACKAGE=package/rattle
DESCRIPTION=$(PACKAGE)/DESCRIPTION
DESCRIPTIN=support/DESCRIPTION.in
NAMESPACE=$(PACKAGE)/NAMESPACE

PPACKAGE=package/pmml
PDESCRIPTION=$(PPACKAGE)/DESCRIPTION

RVER=$(shell R --version | head -1 | cut -d" " -f3 | sed 's|\..$||')
REPOSITORY=repository

# Canonical version information from rattle.R
MAJOR=$(shell egrep '^MAJOR' src/rattle.R | cut -d\" -f 2)
MINOR=$(shell egrep '^MINOR' src/rattle.R | cut -d\" -f 2)
SVNREVIS=$(shell svn info | egrep 'Revision:' |  cut -d" " -f 2)
REVISION=$(shell svn info | egrep 'Revision:' |  cut -d" " -f 2\
            | awk '{print $$1-380}')
VERSION=$(MAJOR).$(MINOR).$(REVISION)
VDATE=$(shell svn info |grep 'Last Changed Date'| cut -d"(" -f2 | sed 's|)||'\
	   | sed 's|^.*, ||')

PVERSION=$(shell egrep ' VERSION <-' src/pmml.R | cut -d \" -f 2)

DATE=$(shell date +%F)

# 080524 add data.R and remove paradigm.R

R_SOURCE = \
	src/rattle.R \
	src/ada.R \
	src/ada_gui.R \
	src/associate.R \
	src/cluster.R \
	src/ctree.R \
	src/data.R \
	src/evaluate.R \
	src/execute.R \
	src/export.R \
	src/hclust.R \
	src/help.R \
	src/kmeans.R \
	src/log.R \
	src/model.R \
	src/nnet.R \
	src/projects.R \
	src/random_forest.R \
	src/report.R \
	src/rpart.R \
	src/test.R \
	src/textview.R \
	src/textminer.R \
	src/transform.R \
	src/zzz.R

# Eventually remove pmml.R from above and put into own package.

PSOURCE = \
	src/pmml.R \
	src/pmml.arules.R \
	src/pmml.kmeans.R \
	src/pmml.hclust.R \
	src/pmml.ksvm.R \
	src/pmml.lm.R \
	src/pmml.multinom.R \
	src/pmml.nnet.R \
	src/pmmltoc.R \
	src/pmml.randomForest.R \
	src/pmml.rpart.R \
	src/pmml.rsf.R

GLADE_SOURCE = src/rattle.glade

SOURCE = $(R_SOURCE) $(GLADE_SOURCE) $(NAMESPACE)

#temp:
#	@echo  $(VDATE)
#temp:
#	@echo rattle_$(VERSION).tar.gz $(VERSION) $(REVISION) $(PVERSION)
#temp:
#	grep REVISION src/rattle.R

default: local plocal

# This one checks the R installations for overlap of packages
# installed. If they are in both local and lib, should remove the
# local one.

checkR:
	ls /usr/local/lib/R/site-library/ > TMPlocal
	ls /usr/lib/R/site-library/ > TMPlib
	meld TMPlocal TMPlib
	rm -f TMPloca TMPlib

#revision:
#	perl -pi -e "s|Revision: \d* |Revision: $(REVISION) |" src/rattle.R

.PHONY: update
update:
	svn update
	svn update

status:
	svn status -q

meld:
	@for i in $(shell svn status -q | awk '{print $$2}'); do\
	  meld $$i;\
	done

diff:
	svn diff

.PHONY: install
install: update build pbuild zip rattle_src.zip # check pcheck
	perl -pi -e "s|version is [0-9\.]*\.|version is $(VERSION).|"\
			changes.html.in
	cp changes.html.in /home/gjw/projects/togaware/www/
	cp todo.html.in /home/gjw/projects/togaware/www/
	(cd /home/gjw/projects/togaware/www/;\
	 perl -pi -e "s|Latest version [0-9\.]* |Latest version $(VERSION) |" \
			rattle.html.in;\
	 perl -pi -e "s|released [^\.]*\.|released $(VDATE).|" \
			rattle.html.in;\
	 perl -pi -e "s|\(revision [0-9]*\)|(revision $(SVNREVIS))|" \
			rattle.html.in;\
	 perl -pi -e "s|rattle_[0-9\.]*zip|rattle_$(VERSION).zip|g" \
			rattle.html.in;\
	 perl -pi -e "s|rattle_[0-9\.]*tar.gz|rattle_$(VERSION).tar.gz|g" \
			rattle.html.in;\
	 perl -pi -e "s|pmml_[0-9\.]*zip|pmml_$(PVERSION).zip|g" \
			rattle.html.in;\
	 perl -pi -e "s|pmml_[0-9\.]*tar.gz|pmml_$(PVERSION).tar.gz|g" \
			rattle.html.in;\
	 perl -pi -e "s|rattle_[0-9\.]*zip|rattle_$(VERSION).zip|g" \
			rattle-download.html.in;\
	 perl -pi -e "s|rattle_[0-9\.]*tar.gz|rattle_$(VERSION).tar.gz|g" \
			rattle-download.html.in;\
	 perl -pi -e "s|pmml_[0-9\.]*zip|pmml_$(PVERSION).zip|g" \
			rattle-download.html.in;\
	 perl -pi -e "s|pmml_[0-9\.]*tar.gz|pmml_$(PVERSION).tar.gz|g" \
			rattle-download.html.in;\
	 make local; lftp -f .lftp-rattle)
	(cd /home/gjw/projects/dmsurvivor/;\
	 perl -pi -e "s|rattle_.*zip|rattle_$(VERSION).zip|g" \
			dmsurvivor.Rnw;\
	 perl -pi -e "s|rattle_.*tar.gz|rattle_$(VERSION).tar.gz|g" \
			dmsurvivor.Rnw)
	mv rattle_$(VERSION).tar.gz pmml_$(PVERSION).tar.gz $(REPOSITORY)
	mv rattle_$(VERSION).zip pmml_$(PVERSION).zip $(REPOSITORY)
	-R --no-save < support/repository.R
	chmod go+r $(REPOSITORY)/*
	lftp -f .lftp

check: build
	R CMD check $(PACKAGE)

pcheck: pbuild
	R CMD check $(PPACKAGE)

# For development, temporarily remove the NAMESPACE so all is exposed.

devbuild:
	mv package/rattle/NAMESPACE .
	cp rattle.R package/rattle/R/
	cp rattle.glade package/rattle/inst/etc/
	R CMD build package/rattle
	mv NAMESPACE package/rattle/

build: data rattle_$(VERSION).tar.gz

pbuild: data pmml_$(PVERSION).tar.gz

rattle_src.zip:
	cp $(R_SOURCE) zipsrc
	cp $(PSOURCE) zipsrc
	cp src/pmmltocibi.R src/all.R zipsrc
	cp $(GLADE_SOURCE) zipsrc
	zip -r9 rattle_src.zip zipsrc
	mv rattle_src.zip /var/www/access/
	chmod go+r /var/www/access/rattle_src.zip

rattle_$(VERSION).tar.gz: $(SOURCE)
	rm -f package/rattle/R/*
	perl -pi -e "s|^VERSION.DATE <- .*$$|VERSION.DATE <- \"Released $(VDATE)\"|" \
             src/rattle.R
	cp $(R_SOURCE) package/rattle/R/
	cp $(GLADE_SOURCE) package/rattle/inst/etc/
	cp odf/data_summary.odt package/rattle/inst/odt/
	perl -p -e "s|^Version: .*$$|Version: $(VERSION)|" < $(DESCRIPTIN) |\
	perl -p -e "s|^Date: .*$$|Date: $(DATE)|" > $(DESCRIPTION)
	R CMD build $(PACKAGE)
	chmod -R go+rX $(PACKAGE)

pmml_$(PVERSION).tar.gz: $(PSOURCE)
	cp $(PSOURCE) package/pmml/R/
	perl -pi -e "s|^Version: .*$$|Version: $(PVERSION)|" $(PDESCRIPTION)
	perl -pi -e "s|^Date: .*$$|Date: $(DATE)|" $(PDESCRIPTION)
	R CMD build $(PPACKAGE)
	chmod -R go+rX $(PPACKAGE)

R4X:
	R CMD build support/r4x/pkg/R4X

data: package/rattle/data/audit.RData package/rattle/data/weather.RData

package/rattle/data/audit.RData: support/audit.R Makefile
	R --no-save --quiet < support/audit.R
	chmod go+r audit.RData audit.csv audit.arff audit_missing.csv
	cp audit.RData audit.csv audit.arff audit_missing.csv data/
	cp audit.RData audit.csv audit.arff audit_missing.csv src/
	cp audit.RData package/rattle/data/
	cp audit.csv package/rattle/inst/csv/
	cp audit.arff package/rattle/inst/arff/
	cp audit.csv /home/gjw/projects/togaware/www/site/rattle/

package/rattle/data/weather.RData: support/weather.R Makefile
	R --no-save --quiet < support/weather.R
	chmod go+r weather.RData weather.csv weather.arff weather_missing.csv
	cp weather.RData weather.csv weather.arff weather_missing.csv data/
	cp weather.RData weather.csv weather.arff weather_missing.csv src/
	cp weather.RData package/rattle/data/
	cp weather.csv package/rattle/inst/csv/
	cp weather.arff package/rattle/inst/arff/
	cp weather.csv /home/gjw/projects/togaware/www/site/rattle/

zip: local plocal
	(cd /usr/local/lib/R/site-library; zip -r9 - rattle) \
	>| rattle_$(VERSION).zip
	(cd /usr/local/lib/R/site-library; zip -r9 - pmml) \
	>| pmml_$(PVERSION).zip

txt:
	R CMD Rd2txt package/rattle/man/rattle.Rd

html:
	for m in rattle evaluateRisk genPlotTitleCmd plotRisk; do\
	  R CMD Rdconv -t=html -o=$$m.html package/rattle/man/$$m.Rd;\
	  epiphany -n $$m.html;\
	  rm -f $$m.html;\
	done

local: rattle_$(VERSION).tar.gz
	R CMD INSTALL --library=/usr/local/lib/R/site-library $^

plocal: pmml_$(PVERSION).tar.gz
	R CMD INSTALL --library=/usr/local/lib/R/site-library $^

access:
	grep 'rattle' /home/gjw/projects/ilisys/log

python:
	python rattle.py

test:
	R --no-save --quiet < regression.R 

ptest:
	r ptest.R

clean:
	rm -f rattle_*.tar.gz rattle_*.zip
	rm -f package/rattle/R/rattle.R package/rattle/inst/etc/rattle.glade
	rm -f package/rattle/DESCRIPTION
	rm -f pmml_*.tar.gz pmml_*.zip

realclean: clean
	rm -f package/rattle/data/audit.RData package/rattle/inst/csv/audit.csv
	rm -f package/rattle/data/weather.RData package/rattle/inst/csv/weather.csv
	rm -rf rattle.Rcheck rattle_$(VERSION).tar.gz
