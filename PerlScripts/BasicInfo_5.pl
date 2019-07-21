my $common_output_path = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/Results/TemporalFiles/BasicInfo/BasicInfo_5/";
my @class_temp_ids = ();
my @explicit_declared_objs = ();
my @not_explicit_declared_objs = ();
my @implicit_declared_objs = ();

## record class templates
processClassTemplate("C Class Template");
processClassTemplate("C Struct Template");
sub processClassTemplate{
	foreach my $class ($db->ents($_[0])){
		my $class_id = $class->id();
		push(@class_temp_ids,$class_id);
	}
}

## detect explicitly declared objects, which are defined with instantiated types
foreach my $obj ($db->ents("C Object")){
	my $flag_is_explicit_declared_obj = 0;
	foreach my $ref ($obj->refs("C Typed")){
		my $ref_ent = $ref->ent();
		next unless $ref_ent;
		my $ref_id = $ref_ent->id();
		# if the object is defined with an instantiated type, record it
		next unless (grep { $_ eq $ref_id } @class_temp_ids);
		push(@explicit_declared_objs,$obj);
		$flag_is_explicit_declared_obj = 1;
		my $obj_name = $obj->name;
		last;
	}
	# if the object is not defined with an instantiated type, record it
	if(!$flag_is_explicit_declared_obj){
		push(@not_explicit_declared_objs,$obj);
	}
}

## detect implicitly declared objects, which are defined with "auto" and intantiated type
foreach my $obj (@not_explicit_declared_objs){
	my $obj_name = $obj->name();
	foreach my $ref ($obj->refs("C Definein")){
		if(checkIsDefinedWithAuto($ref,$obj_name)){
			push(@implicit_declared_objs,$obj);
		}
		last;
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

# subprogram to check whether an object is defined with instantiated type
sub checkIsDefinedWithInstantiatedType{
	my ($ref) = @_;
	my $lex = $ref->lexeme();
	$lex = $lex->next();
	return 0 unless $lex;
	while(($lex->text) eq " " || ($lex->text) eq "\n"){
		$lex = $lex->next();
		return 0 unless $lex;
	}
	return 0 unless $lex;
	return 0 unless ($lex->text eq "=");
	do{
		$lex = $lex->next();
		return 0 unless $lex;
	}while(($lex->text) eq " " || ($lex->text) eq "\n");
	return 0 unless ($lex->text eq "new");
	do{
		$lex = $lex->next();
		return 0 unless $lex;
	}while(($lex->text) eq " " || ($lex->text) eq "\n");
	my $cur_ent = $lex->ent();
	return 0 unless $cur_ent;
	my $parent_ent = $cur_ent->parent();
	return 0 unless $parent_ent;
	my $ent_id = $parent_ent->id;
	# if the object is defined with an instantiated type, return 1
	if(grep { $_ eq $ent_id } @class_temp_ids){
		return 1;
	}
	return 0;
}

# ===============================================================================================================================================
# write information into excel
my $output_path = $common_output_path.$proj_name."_BasicInfo_5.csv";
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
