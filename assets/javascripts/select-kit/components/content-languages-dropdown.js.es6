import DropdownSelectBox from "select-kit/components/dropdown-select-box";

export default DropdownSelectBox.extend({
  classNames: "content-languages-dropdown",  
  valueProperty: "code",
  nameProperty: "name",
  
  selectKitOptions: {
    icon: "translate",
    showFullTitle: false,
    autoFilterable: false,
    filterable: false,
    headerComponent: "content-languages-header"
  },
  
  modifyComponentForRow() {
    return "content-languages-row";
  }
});