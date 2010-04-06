all:
	echo "Add 'clean' to clean sources";
	
clean:
	rm -f makefile~
	find ./framework/common/matlab -name "*.m~" -exec rm {} \;
	find ./framework/common/matlab -name "*.asv" -exec rm {} \;
	find ./framework/common/matlab -name "*.c~" -exec rm {} \;
	find ./framework/common/matlab -name "*.cpp~" -exec rm {} \;	
	find ./framework/common/matlab -name "*.h~" -exec rm {} \;	

