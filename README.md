# S1000D BREX to Schematron

The `S1000D-BREX-to-Schematron.xsl` file will convert a standard S1000D BREX into a Schematron file.

The resultant Schematron file can then be used to validate you S1000D Data Modules source data in any number of different XML editors.

## Arbortext Editor

Once configured, click the **Check Completeness** icon ![Arbortext Completeness Check icon.](img/arbortext-check-completeness-v1.png) to validate you Data Module

![Screenshot](img/arbortext-editor-validation-v1.png)

Please contact [Docuneering Ltd.](https://www.docuneering.com/contact/) for details on how to configure BREX/Schematron validation in Arbortext Editor.

## Oxygen XML Editor

You need to configure a validation scenario within your framework. Once setup, Oxygen XML Editor implements a **live** or **on-the-fly** validation process:

![Screenshot](img/oxygen-xml-validation-v1.png)

Please contact [Docuneering Ltd.](https://www.docuneering.com/contact/) for details on how to configure a validation scenario within Oxygen XML Editor.

---
## Convertion Process

The simplest way to convert an S1000D BREX file to Schematron is to use Saxon and the commend line.

### Command line

`java -jar "saxon-he-10.9.jar" -xsl:"S1000D-BREX-to-Schematron.xsl" -s:"TEST42-BREX.XML" -o:"TEST42-BREX.SCH"`

