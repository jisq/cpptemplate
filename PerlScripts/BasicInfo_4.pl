my $common_output_path = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/Results/TemporalFiles/BasicInfo/BasicInfo_4/";
my @explicit_declared_objs = ();
my @implicit_declared_objs = ();

## detect explicitly and implicitly declared objects which are defined with instantiated types
foreach my $obj ($db->ents("C Object")){
	my $obj_name = $obj->name();
	my $obj_type = $obj->type();
	# detect objects which are defined with instantiated types
	if($obj_type =~ /</ and $obj_type =~ />/){
		foreach my $ref ($obj->refs("C Definein")){
			if(checkIsDefinedWithAuto($ref,$obj_name)){
				push(@implicit_declared_objs,$obj);
			} else{
				push(@explicit_declared_objs,$obj);
			}
			last;
		}
	}
}

## ==========================================================
# subprogram to check whether an object is implicitly defined
sub checkIsDefinedWithAuto{
	my ($ref, $obj_name) = @_;
	my $lex = $ref->lexeme();
	while(($lex->text) eq " " || ($lex->text) eq "\n"){
		$lex = $lex->previous();
		return 0 unless $lex;
	}
	return 0 unless $lex;
	return 0 unless ($lex->text eq $obj_name);
	do{
		$lex = $lex->previous();
		return 0 unless $lex;
	}while(($lex->text) eq " " || ($lex->text) eq "\n");
	return 0 unless $lex;
	if($lex->text eq "auto"){
		return 1;
	}
	return 0;
}

# ===============================================================================================================================================
# write information into excel
my $output_path = $common_output_path.$proj_name."_BasicInfo_4.csv";
if(-e $output_path){
	unlink $output_path;
}
open("metricfile", ">>$output_path");
# print info of implicitly declared objects
print("======implicit declarations=======\n");
syswrite("metricfile", "object defined with implicit instantiated type, file, line\n");
foreach my $obj (@implicit_declared_objs){
	foreach my $ref ($obj->refs("C Definein")){
		my $obj_name = $obj->name();
		my $ref_file = $ref->file->longname();
		my $ref_line = $ref->line();
		syswrite("metricfile", "$obj_name, //$ref_file, //$ref_line\n");
		print($proj_name."===".$obj_name.",".$ref_file.",".$ref_line."\n");
		last;
	}
}
syswrite("metricfile", "\n");
# print info of explicitly declared objects
print("======explicit declarations=======\n");
syswrite("metricfile", "object defined with explicit instantiated type, file, line\n");
foreach my $obj (@explicit_declared_objs){
	foreach my $ref ($obj->refs("C Definein")){
		my $obj_name = $obj->name();
		my $ref_file = $ref->file->longname();
		my $ref_line = $ref->line();
		syswrite("metricfile", "$obj_name, //$ref_file, //$ref_line\n");
		print($proj_name."===".$obj_name.",".$ref_file.",".$ref_line."\n");
		last;
	}
}
close("metricfile");

$db->close();
