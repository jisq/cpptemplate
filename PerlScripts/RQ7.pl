
my $common_output_path = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/Results/TemporalFiles/RQ7/";
my $namespace_mark = "::";
my $third_party_lib_prefix = "boost::|bdlt::|dlib::|juce::|loki::|Reason::|folly::|cxxomfort::|scy::|Upp::|caf::|glm::|miniupnpc::|quesoglc::|sdl::|WTL::|scintilla::|leveldb::
|json_spirit::|ATL::|vcg::|hull::|yaSSL::|TaoCrypt::|KFS::|antlr::|dena::|open_query::|agg::|Imath::|Eigen::|sg::|carve::|libmv::|TNT::|BasicVector::|Py::|utf8::";
my $std_lib_prefix = "std::";
my $third_party_lib_path = "ext/|json/|leveldb/|TabbingFramework/|thirdparty/|3rdparty/|3rdParty/|third_party/|ThirdParty/|OublietteImport/Extern/|external/|extra/|zlib/
|libevent/|libmysql/|libmysqld/|libservices/|contrib/|SageIII/qtools/|libmd5/|utf8/|wxWidgets-2.9.1/|libclamav/";

my $user_def_class_template_use_for_derivation = 0;
my $lib_class_template_use_for_derivation = 0;

sub calculateTempUses{
	my $ent_kind = $_[0];
	foreach my $class ($db->ents($ent_kind)){
		my $class_name = $class->longname();
		my $is_user_def_template = 1;
		my $PublicDerive = 0;
		my $ProtectedDerive = 0;
		my $PrivateDerive = 0;
		my @metriclist = ("AltCountLineCode");
		my @value = $class->metric(@metriclist);
		# to determine whether it is a library template
		if(not defined($value[0])){
			$is_user_def_template = 0;
			if($class_name !~ /$namespace_mark/){
				next;
			}
			if($class_name !~ /$std_lib_prefix/ and $class_name !~ /($third_party_lib_prefix)/){
				next;
			}
		}
		# to determine whether it is a 3rd-party library template
		elsif($class_name =~ /($third_party_lib_prefix)/){
			$is_user_def_template = 0;
		}
		my $defined_in_cpp = 1;
		foreach my $ref ($class->refs()){
			my $ref_name = $ref->kind()->longname();
			# process class template definition
			if($ref_name eq "C Definein"){
				my $ref_file = $ref->file->longname();
				$defined_in_cpp = 0 if $ref_file !~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/;
				$is_user_def_template = 0 if $ref_file =~ /($third_party_lib_path)/;
				last;
			}
		}
		next unless $defined_in_cpp;
		# traverse the refs in valid C++ files
		foreach my $ref ($class->refs()){
			my $ref_file = $ref->file()->longname();
			if($ref_file =~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/ and $ref_file !~ /($third_party_lib_path)/){
				my $ref_name = $ref->kind()->longname();
				# to find out the derivations
				SWITCH: {
					$ref_name eq "C Public Derive" && do { $PublicDerive ++; last SWITCH; };
					$ref_name eq "C Protected Derive" && do { $ProtectedDerive ++; last SWITCH; };
					$ref_name eq "C Private Derive" && do { $PrivateDerive ++; last SWITCH; };
				}
			}
		}
		# if it is a user-defined template
		if($is_user_def_template == 1){
			$user_def_class_template_use_for_derivation += $PublicDerive + $ProtectedDerive + $PrivateDerive;
		}
		# if it is a library template
		else{
			$lib_class_template_use_for_derivation += $PublicDerive + $ProtectedDerive + $PrivateDerive;
		}
	}
}

# ===============================================================================================================================================
# process class templates
print $proj_name."========================class\n";
calculateTempUses("C Class Template");
print $proj_name."========================struct\n";
calculateTempUses("C Struct Template");

# ===============================================================================================================================================
# write info into excel
my $output_path = $common_output_path.$proj_name."_RQ7.csv";
if(-e $output_path){
	unlink $output_path;
}
open("metricfile", ">>$output_path");
syswrite("metricfile", "derivations of library class templates, derivations of user-defined class templates\n");
syswrite("metricfile", "$lib_class_template_use_for_derivation, //$user_def_class_template_use_for_derivation\n");
close("metricfile");
