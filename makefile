# Expermental Makefile to make CPAN bundles.
# Subject to change, or throwaway, without notice.

# NO WARRANTY

# default target if non name is given
allx: all

ALL=

ALL_MODULES = $(shell ls */MANIFEST | sed -e 's|/MANIFEST|.gz|' | sort -f)

.PHONY:  all allx all_modules clean realclean $(ALL_MODULES)

ALL += $(ALL_MODULES)


$(ALL_MODULES):
	echo ALL_MODULES
	@set -xeu; \
	PATH=".:$$PATH"; \
	gz=$@; \
	cd $${gz%.gz}; \
	VERSION=`awk '/[^#]VERSION/ {gsub("[^._0-9]", "", $$3); print $$3; exit 0;}' VERSION_PACKAGE`; \
	gz_ver="$${gz%.gz}-$$VERSION.tar.gz"; \
	if grep -q MANIFEST.SKIP MANIFEST; then \
	   copy="true 1"; \
	   if [ -f "MANIFEST.SKIP" ] && \
	      grep -q .gitignore MANIFEST.SKIP ]; then copy="false 2"; \
	   fi;\
	   if $$copy; then \
	      if [ MANIFEST.SKIP -ot .gitignore ] && \
	         [ MANIFEST.SKIP -ot ../.gitignore ]; then \
		copy="false 3"; \
	      fi; \
	      awker() { awk '/MANIFEST.SKIP/ {exit 0} /^#/ {next} {print}' $$*; }; \
	      if $$copy; then \
	      	true; \
	         ( awker ../.gitignore; \
		   if [ -s .gitignore ]; then awker .gitignore; fi; \
		 ) | \
	         ( date "+#generated %Y-%m-%d %H:%M:%S"; sort -fu ) | \
		 sed -e 's/\./[.]/g' -e 's/\*/.*/g' -e 's/^\.\*//' -e 's/$$/$$/' >MANIFEST.SKIP; \
	      fi; \
	  fi; \
	fi; \
	rm -rf LICENSES; \
	mkdir LICENSES; \
	cp -p ../LICENSE* LICENSES/.; \
	if [ -f Makefile.PL ]; then \
	   m=Makefile; \
	   x=make;  \
	else \
	   m=Build; \
	   x=Build; \
	fi; \
	if [ -e $$m ]; then $$x realclean; fi; \
	perl $$m.PL; \
	rm -f "$$gz_ver"; \
	$$x dist; \
	if [ ! -f ../$$gz_ver ] || ! zcmp -s ../$$gz_ver $$gz_ver; then \
	    echo "Copying to ../$$gz_ver"; \
	    cp -p "$$gz_ver" "../$$gz_ver"; \
	else \
	    echo "Same ../$$gz_ver"; \
	fi; \
	echo done
	

all: $(ALL)
	echo ALL="$(ALL)"

all_modules:
	@echo $(ALL_MODULES)


clean:
	rm -f $(ALL_MODULES)

realclean: clean
	rm -rf */LICENSES
	for skip in */MANIFEST.SKIP; do if grep '#generated' $$skip; then rm $$skip; fi; done

#end: Makefile
