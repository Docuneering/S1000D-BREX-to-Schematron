<?xml version="1.0" encoding="UTF-8"?>
<!-- ===========================================================================================
   Copyright (c) 2024 Docuneering Ltd. 

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
=========================================================================================== -->

<xsl:stylesheet 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:sch="http://purl.oclc.org/dsdl/schematron" 
	version="2.0">
	
	<xsl:output
		method="xml"
		omit-xml-declaration="no"
		encoding="UTF-8"
		indent="yes"/>
	
	<xsl:strip-space elements="*"/>

	<xsl:template match="/">
		<xsl:choose>
			
			<!-- Check we are in a BREX Data Module -->
			<xsl:when test="/dmodule/identAndStatusSection/dmAddress/dmIdent/dmCode[@infoCode='022'] and /dmodule/content/brex">
				
				<!-- Output the root Schematron element -->
				<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
					
					<!-- Schematron namespace(s) -->
					<sch:ns prefix="xsi" uri="http://www.w3.org/2001/XMLSchema-instance" />
					<sch:ns prefix="rdf" uri="http://www.w3.org/1999/02/22-rdf-syntax-ns#" />
					
					<!-- For each "structureObjectRule" we find -->
					<xsl:for-each select="/dmodule/content/brex/contextRules/structureObjectRuleGroup/structureObjectRule">
						
						<!-- Populate common variables -->
						
						<!-- Convert any double quotes into single quotes e.g. From " to ' -->
						<xsl:variable name="objectPath">
							<xsl:value-of select="replace(objectPath,'&quot;','''')"/>
						</xsl:variable>

						<!-- Check if these rules are schema specific -->
						<xsl:variable name="rulesContext">
							<xsl:choose>
								<xsl:when test="ancestor::contextRules/@rulesContext">
									<xsl:text>(//@xsi:noNamespaceSchemaLocation='</xsl:text>
									<xsl:value-of select="ancestor::contextRules/@rulesContext"/>
									<xsl:text>') and </xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<!-- Do nothing -->
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>

						<!-- Create the "objectValueSingle" variable -->
						<xsl:variable name="objectValueSingle">
							<xsl:for-each select="objectValue[@valueForm='single']">
								<xsl:if test="count(preceding-sibling::objectValue) &gt; 0">
									<xsl:text> or </xsl:text>
								</xsl:if>
								<xsl:text>.='</xsl:text>
								<xsl:value-of select="@valueAllowed"/>
								<xsl:text>'</xsl:text>
							</xsl:for-each>
						</xsl:variable>
						
						<!-- Create the "objectValueRange" variable -->
						<xsl:variable name="objectValueRange">
							<xsl:for-each select="objectValue[@valueForm='range']">
								<xsl:variable name="valueAllowed">
									<xsl:value-of select="@valueAllowed"/>
								</xsl:variable>
								<xsl:if test="count(preceding-sibling::objectValue) &gt; 0">
									<xsl:text> or </xsl:text>
								</xsl:if>
								<xsl:text>(.&gt;=$from</xsl:text>
								<xsl:value-of select="count(preceding-sibling::objectValue)+1"/>
								<xsl:text> and .&lt;=$to</xsl:text>
								<xsl:value-of select="count(preceding-sibling::objectValue)+1"/>
								<xsl:text>)</xsl:text>
							</xsl:for-each>
						</xsl:variable>
						
						<!-- Create the "objectValuePattern" variable -->
						<xsl:variable name="objectValuePattern">
							<xsl:for-each select="objectValue[@valueForm='pattern']">
								<xsl:if test="count(preceding-sibling::objectValue) &gt; 0">
									<xsl:text> or </xsl:text>
								</xsl:if>
								<xsl:text>matches(.,'</xsl:text>
								<xsl:value-of select="@valueAllowed"/>
								<xsl:text>')</xsl:text>
							</xsl:for-each>
						</xsl:variable>
						
						<!-- List the "objects" in the "objectValue" variable -->
						<xsl:variable name="objectValue">
							<xsl:value-of select="$objectValueRange"/>
							<xsl:value-of select="$objectValueSingle"/>
							<xsl:value-of select="$objectValuePattern"/>
						</xsl:variable>

						<!-- Select the @allowedObjectFlag= '0', '1' or '2' -->
						<xsl:choose>
							
							<!-- =========================================================================================== -->
							<xsl:when test="objectPath/@allowedObjectFlag='0'">
								<!-- "0" - No, the object must not be used in the context concerned -->
								<sch:pattern>
									<sch:rule>
										<!-- Define the "context" attribute value -->
										<xsl:attribute name="context">
											<!--  -->
											<xsl:value-of select="$objectPath"/>
											<xsl:if test="ancestor::contextRules/@rulesContext">
												<xsl:text>[ancestor::*/@xsi:noNamespaceSchemaLocation='</xsl:text>
												<xsl:value-of select="ancestor::contextRules/@rulesContext"/>
												<xsl:text>']</xsl:text>
											</xsl:if>
										</xsl:attribute>
										
										<!-- Build: Convert "range" values into "<sch:let> elements -->
										<xsl:call-template name="buildRange"/>
										
										<!-- Report: If it finds it, it reports the message  -->
										<sch:report>
											<xsl:attribute name="test">
												<xsl:choose>
													<xsl:when test="$objectValue!=''">
														<xsl:value-of select="$rulesContext" disable-output-escaping="yes"/>
														<xsl:if test="$rulesContext!=''">
															<xsl:text>(</xsl:text>
														</xsl:if>
														<xsl:value-of select="$objectValue"/>
														<xsl:if test="$rulesContext!=''">
															<xsl:text>)</xsl:text>
														</xsl:if>
													</xsl:when>
													<xsl:otherwise>
														<xsl:value-of select="concat($rulesContext,$objectPath)" disable-output-escaping="yes"/>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:attribute>
											<!--<xsl:text>BREX: </xsl:text>-->
											<xsl:value-of select="objectUse"/>
										</sch:report>
									</sch:rule>
								</sch:pattern>
							</xsl:when>
							
							<!-- =========================================================================================== -->
							<xsl:when test="objectPath/@allowedObjectFlag='1'">
								<!-- "1" - Yes, the object must be included in the context concerned -->
								<sch:pattern>
									<sch:rule>
										<!-- Define the "context" attribute value -->
										<xsl:attribute name="context">
											<xsl:choose>
												<!-- If this is just an @attribute lookup -->
												<xsl:when test="starts-with($objectPath,'//@')">
													<xsl:value-of select="$objectPath"/>
												</xsl:when>
												<!-- Remove attribute to leave just the element(s) -->
												<xsl:when test="contains($objectPath,'/@')">
													<xsl:variable name="step1">
														<xsl:value-of select="tokenize($objectPath,'/@')[1]"/>
													</xsl:variable>
													<xsl:value-of select="$step1"/>
												</xsl:when>
												<!-- Remove the last element as it might not be located in the XML file -->
												<xsl:when test="contains($objectPath,'/')">
													<xsl:variable name="step1">
														<xsl:value-of select="tokenize($objectPath,'/')[last()]"/>
													</xsl:variable>
													<xsl:variable name="step2">
														<xsl:text>/</xsl:text>
														<xsl:value-of select="$step1"/>
													</xsl:variable>
													<xsl:variable name="step3">
														<xsl:value-of select="replace($objectPath,$step2,'')"/>
													</xsl:variable>
													<xsl:value-of select="$step3"/>
												</xsl:when>
												<!-- Not sure we should be using '=' in the <objectPath>. -->
												<!-- I feel this should be done with @allowedObjectFlag='2' -->
												<xsl:when test="contains($objectPath,'=')">
													<xsl:variable name="step1">
														<xsl:value-of select="tokenize($objectPath,'=')[1]"/>
													</xsl:variable>
													<xsl:variable name="step2">
														<xsl:value-of select="replace($step1,'\(','')"/>
													</xsl:variable>
													<xsl:variable name="step3">
														<xsl:choose>
															<xsl:when test="contains($objectPath,'[')">
																<xsl:value-of select="tokenize($step2,'\[')[1]"/>
															</xsl:when>
															<xsl:otherwise>
																<xsl:value-of select="$step2"/>
															</xsl:otherwise>
														</xsl:choose>
													</xsl:variable>
													<xsl:value-of select="$step3"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="$objectPath"/>
												</xsl:otherwise>
											</xsl:choose>
											<xsl:if test="ancestor::contextRules/@rulesContext">
												<xsl:text>[ancestor::*/@xsi:noNamespaceSchemaLocation='</xsl:text>
												<xsl:value-of select="ancestor::contextRules/@rulesContext"/>
												<xsl:text>']</xsl:text>
											</xsl:if>
										</xsl:attribute>
										
										<!-- Build: Convert "range" values into "<sch:let> elements -->
										<xsl:call-template name="buildRange"/>
										
										<!-- Report: If it finds it, it reports the message  -->
										<sch:report>
											<xsl:attribute name="test">
												<xsl:choose>
													<xsl:when test="$objectValue!=''">
														<xsl:value-of select="$rulesContext" disable-output-escaping="yes"/>
														<xsl:if test="$rulesContext!=''">
															<xsl:text>not(</xsl:text>
														</xsl:if>
														<xsl:value-of select="$objectValue"/>
														<xsl:if test="$rulesContext!=''">
															<xsl:text>)</xsl:text>
														</xsl:if>
													</xsl:when>
													<xsl:otherwise>
														<!--<xsl:value-of select="concat($rulesContext,$objectPath)" disable-output-escaping="yes"/>-->
														<xsl:value-of select="$rulesContext" disable-output-escaping="yes"/>
														<xsl:if test="$rulesContext!=''">
															<xsl:text>not(</xsl:text>
														</xsl:if>
														<xsl:value-of select="$objectPath" disable-output-escaping="yes"/>
														<xsl:if test="$rulesContext!=''">
															<xsl:text>)</xsl:text>
														</xsl:if>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:attribute>
											<!--<xsl:text>BREX: </xsl:text>-->
											<xsl:value-of select="objectUse"/>
										</sch:report>
									</sch:rule>
								</sch:pattern>
							</xsl:when>
							
							<!-- =========================================================================================== -->
							<xsl:when test="objectPath/@allowedObjectFlag='2'">
								<!-- "2" (D) - the object can optionally be used in the context concerned, however, fully in accordance with the specification text and the Schemas -->
								<sch:pattern>
									<sch:rule>
										<!--  -->
										<xsl:attribute name="context">
											<xsl:value-of select="$objectPath"/>
											<xsl:if test="ancestor::contextRules/@rulesContext">
												<xsl:text>[ancestor::*/@xsi:noNamespaceSchemaLocation='</xsl:text>
												<xsl:value-of select="ancestor::contextRules/@rulesContext"/>
												<xsl:text>']</xsl:text>
											</xsl:if>
										</xsl:attribute>
										
										<!-- Build: Convert "range" values into "<sch:let> elements -->
										<xsl:call-template name="buildRange"/>

										<!-- Assert: If it doesn't finds it, it reports the message -->
										<sch:assert>
											<xsl:attribute name="test">
												<!--  -->
												<xsl:choose>
													<xsl:when test="$objectValue!=''">
														<xsl:value-of select="$rulesContext" disable-output-escaping="yes"/>
														<xsl:if test="$rulesContext!=''">
															<xsl:text>not(</xsl:text>
														</xsl:if>
														<xsl:value-of select="$objectValue"/>
														<xsl:if test="$rulesContext!=''">
															<xsl:text>)</xsl:text>
														</xsl:if>
													</xsl:when>
													<xsl:otherwise>
														<xsl:value-of select="$rulesContext" disable-output-escaping="yes"/>
														<xsl:value-of select="$objectPath"/>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:attribute>
											<!--<xsl:text>BREX: </xsl:text>-->
											<xsl:value-of select="objectUse"/>
										</sch:assert>
									</sch:rule>
								</sch:pattern>
								
							</xsl:when>
						</xsl:choose>
					</xsl:for-each>
				</sch:schema>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>ERROR: Please select an S1000D BREX Data Module file to convert.</xsl:text>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>
	
	
	<!-- Convert "range" values into "<sch:let> elements -->
	<xsl:template name="buildRange">
		<xsl:for-each select="objectValue[@valueForm='range']">
			<xsl:variable name="valueAllowed">
				<xsl:value-of select="@valueAllowed"/>
			</xsl:variable>
			<sch:let>
				<xsl:attribute name="name">
					<xsl:text>from</xsl:text>
					<xsl:value-of select="count(preceding-sibling::objectValue)+1"/>
				</xsl:attribute>
				<xsl:attribute name="value">
					<xsl:text>'</xsl:text>
					<xsl:value-of select="tokenize($valueAllowed, '~')[1]"/>
					<xsl:text>'</xsl:text>
				</xsl:attribute>
			</sch:let>
			<sch:let>
				<xsl:attribute name="name">
					<xsl:text>to</xsl:text>
					<xsl:value-of select="count(preceding-sibling::objectValue)+1"/>
				</xsl:attribute>
				<xsl:attribute name="value">
					<xsl:text>'</xsl:text>
					<xsl:value-of select="tokenize($valueAllowed, '~')[last()]"/>
					<xsl:text>'</xsl:text>
				</xsl:attribute>
			</sch:let>
		</xsl:for-each>
	</xsl:template>
	
	
</xsl:stylesheet>