"
    Copyright (c) 2020 Aucerna. 
    See (MIT) license in root directory.
"

Class {
	#name : #Module,
	#superclass : #Object,
	#instVars : [
		'name',
		'version',
		'exports',
		'namespace',
		'hash',
		'cachedLookups',
		'classes',
		'extensions',
		'overriden'
	],
	#category : #Kernel
}

{ #category : #services }
Module >> addClass: aClass [
	classes add: aClass.
	self exportClass: aClass
]

{ #category : #initializing }
Module >> basicInitialize [
	name := self defaultName.
	exports := Set new.
	cachedLookups := Dictionary new.
	classes := OrderedCollection new.
	extensions := Dictionary new.
	overriden := Dictionary new
]

{ #category : #services }
Module >> bind: anObject as: aSymbol [
	namespace at: aSymbol put: anObject.
	self justDefined: aSymbol
]

{ #category : #private }
Module >> bindAllIn: aModule [
	aModule exports keysAndValuesDo: [:symbol :value |
		namespace at: symbol put: value.
		self justDefined: symbol].
]

{ #category : #services }
Module >> bindKernelExports [
	self bindAllIn: Kernel
]

{ #category : #accessing }
Module >> classes [
	^classes
]

{ #category : #initialization }
Module >> defaultName [
	| classname i |
	classname := self class name.
	i := classname indexOfString: 'Module'.
	^i = 0 ifTrue: [classname] ifFalse: [classname copyTo: i - 1]
]

{ #category : #services }
Module >> exports [
	| result |
	result := Dictionary new.
	exports do: [:name | | value |
		value := namespace at: name.
		result at: name put: value].
	^result
]

{ #category : #services }
Module >> export: anObject as: aSymbol [
	namespace at: aSymbol put: anObject.
	exports add: aSymbol
]

{ #category : #services }
Module >> exportClass: aClass [
	self export: aClass as: aClass name asSymbol
]

{ #category : #accessing }
Module >> extensions [
	^extensions
]

{ #category : #services }
Module >> import: name from: moduleName [
	| module import |
	module := self require: moduleName.
	import := module namespace at: name.
	self bind: import as: name
]

{ #category : #initializing }
Module >> initialize [
	name := self basicInitialize.
	namespace := Namespace new.
]

{ #category : #private }
Module >> justDefined: aSymbol [
	| lookups |
	lookups := cachedLookups at: aSymbol ifAbsent: [^nil].
	lookups do: [:lookup | lookup flush]
]

{ #category : #bootstrapping }
Module >> loadRequiredModules [
	self requires do: [:name | self import: name]
]

{ #category : #accessing }
Module >> namespace [
	^namespace
]

{ #category : #accessing }
Module >> originalMethodFor: aCompiledMethod [
	"TODO: implement. it should look in the overriden methods"
	^aCompiledMethod
]

{ #category : #accessing }
Module >> overriden [
	^overriden
]

{ #category : #accessing }
Module >> requires [
	^#()
]

{ #category : #services }
Module >> require: moduleName [
	| module |
	namespace at: moduleName ifPresent: [:loaded | ^loaded].
	module := Kernel loadModule: moduleName.
	self bind: module as: moduleName.
	^module
]
