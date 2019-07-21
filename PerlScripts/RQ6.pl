
my $output_path = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/Results/TemporalFiles/RQ6/".$proj_name."_RQ6.csv";
my $third_party_lib_path = "ext/|json/|leveldb/|TabbingFramework/|thirdparty/|3rdparty/|3rdParty/|third_party/|ThirdParty/|OublietteImport/Extern/|external/|extra/|zlib/
|libevent/|libmysql/|libmysqld/|libservices/|contrib/|SageIII/qtools/|libmd5/|utf8/|wxWidgets-2.9.1/|libclamav/";
my $namespace_mark = "::";
my $std_lib_prefix = "std::";

my %class_rec;
my %func_rec;

## processing all classes
print $proj_name."========================processing STL types\n";
my $total_class_num = 0;
my $total_class_instantiations = 0;
processClasses("C Class Template");
processClasses("C Struct Template");
sub processClasses{
	my $ent_kind = shift;
	foreach my $class ($db->ents($ent_kind)){
		my $class_name = $class->longname();
		# determine whether it is a library class
		my @metriclist = ("AltCountLineCode");
		my @value = $class->metric(@metriclist);
		my $is_defined_in_cpp = 1;
		# if it is not a library function, ignore it
		if(defined($value[0])){
			next;
		}
		if($class_name !~ /$std_lib_prefix/){
			next;
		}
		my $is_parsed = 0;
		foreach my $ref ($class->refs()){
			my $ref_name = $ref->kind()->longname();
			# if the class is used in valid C++ files
			if($ref_name eq "C Typedby" or $ref_name eq "C Useby" or $ref_name eq "C Inactive Useby" 
			or $ref_name eq "C Cast Useby" or $ref_name or $ref_name eq "C Nameby" or $ref_name eq "C Friendby"){
				my $ref_file = $ref->file->longname();
				next if $ref_file !~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/;
				next if $ref_file =~ /($third_party_lib_path)/;
				if(exists($class_rec{$class_name})){
					$class_rec{$class_name} ++;
				} else{
					$class_rec{$class_name} = 1;
				}
				$total_class_instantiations ++;
				$is_parsed = 1 unless $is_parsed;
			}
		}
		$total_class_num ++ if $is_parsed;
	}
}

## processing all functions
print $proj_name."========================processing STL functions\n";
my $total_func_num = 0;
my $total_func_instantiations = 0;
foreach my $func ($db->ents("C Function Template")){
	my $func_name = $func->longname();
	# determine whether it is a library function
	my @metriclist = ("AltCountLineCode");
	my @value = $func->metric(@metriclist);
	my $is_defined_in_cpp = 1;
	# if it is not a library function, ignore it
	if(defined($value[0])){
		next;
	}
	if($func_name !~ /$std_lib_prefix/){
		next;
	}
	my $is_parsed = 0;
	foreach my $ref ($func->refs()){
		my $ref_name = $ref->kind()->longname();
		# if the function is called in valid C++ files
		if($ref_name eq "C Callby"){
			my $ref_file = $ref->file->longname();
			next if $ref_file !~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/;
			next if $ref_file =~ /($third_party_lib_path)/;
			if(exists($func_rec{$func_name})){
				$func_rec{$func_name} ++;
			} else{
				$func_rec{$func_name} = 1;
			}
			$total_func_instantiations ++;
			$is_parsed = 1 unless $is_parsed;
		}
	}
	$total_func_num ++ if $is_parsed;
}

# write STD function and class use information into csv files
# ===============================================================================================================================================
if(-e $output_path){
	unlink $output_path;
}
open("metricfile", ">>$output_path");
syswrite("metricfile", "total STL types, total instantiations of STL types, total STL functions, total instantiations of STL functions\n");
syswrite("metricfile", "$total_class_num, $total_class_instantiations, $total_func_num, $total_func_instantiations\n\n");

syswrite("metricfile", "STL type, instantiations\n");
foreach my $key (keys %class_rec){
	my $instantiations = $class_rec{$key};
	syswrite("metricfile", "$key, $instantiations\n");
}
syswrite("metricfile", "\n");
## write information about instantiation of STL functions
syswrite("metricfile", "STL function, function calls\n");
foreach my $key (keys %func_rec){
	my $instantiations = $func_rec{$key};
	syswrite("metricfile", "$key, $instantiations\n");
}
syswrite("metricfile", "\n");

close("metricfile");
