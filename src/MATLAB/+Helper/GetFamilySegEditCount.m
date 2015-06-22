function segEditCount = GetFamilySegEditCount(familyID, bIncludeUser, bIncludeAuto)
    global EditList
    
    famHulls = Families.GetAllHulls(familyID);
    
    bChkEdits = arrayfun(@(x)((x.bUserEdit && bIncludeUser) || (~x.bUserEdit && bIncludeAuto)), EditList);
    chkEdits = EditList(bChkEdits);
    
    bEdgeEdits = arrayfun(@(x)(strcmp(x.action,'SetEdge') || strcmp(x.action,'RemoveEdge') || strcmp(x.action,'Mitosis')), chkEdits);
    segEdits = chkEdits(~bEdgeEdits);
    
    bFamSegEdit = arrayfun(@(x)(any(ismember(x.output,famHulls))), segEdits);
    
    segEditCount = nnz(bFamSegEdit);
end