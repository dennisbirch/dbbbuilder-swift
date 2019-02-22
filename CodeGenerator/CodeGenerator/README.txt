This "CodeGenerator" project is a helper application for DBBBuilder that can generate the boilerplate required to set up a DBBTableObject subclass, which is used by DBBBuilder to model all objects.

To use this project, launch it in Xcode and type or paste a comma-, return-, or space-delimited list of property names into the "Input" text view. Choose a "Default var type" from the popup button in the upper left of the screen. This var type will set the output to use the type you choose for all properties, so pick the one that will require the least editing after copying it into your actual project. Then enter the name of the class to generate in the "Class name" textfield.

Hit the "Generate Code" button and the project will populate the "Output" text view with a complete class definition that includes a struct of Key names, property declarations, and an init method that adds each property to the DBBManager instance's persistenceMap.

You can copy this code to the clipboard by hitting the "Copy Code" button, and then paste it into your DBBTableObject subclass code file. Be sure to change the property declarations and persistence map types for any properties that were not of the default type you selected in the generator default type popup.

