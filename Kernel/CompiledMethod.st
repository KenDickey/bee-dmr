"
    Copyright (c) 2020 Aucerna. 
    Copyright (c) 2020 LabWare.
    See (MIT) license in root directory.
"

Class {
	#name : #CompiledMethod,
	#superclass : #Array,
	#type : #variable,
	#instVars : [
		'format',
		'optimizedCode',
		'astcodes',
		'class',
		'selector',
		'source'
	],
	#classVars : [
		'Flags'
	],
	#category : #Kernel
}

{ #category : #inspecting }
CompiledMethod class >> aspects [
	^#(#astcodeString #disassembledText)
]

{ #category : #initialization }
CompiledMethod class >> initializeFormatFlags [
	Flags := self addNamespace.
	Flags
		at: #ArgCount put: (1 thru: 6);
		at: #BlockCount put: (7 thru: 13);
		at: #TempCount put: (14 thru: 21);
		at: #CapturesSelf put: (1 bitShift: 22 - 1);
		at: #HasEnvironment put: (1 bitShift: 23 - 1);
		at: #HasFrame put: (1 bitShift: 24 - 1);
		at: #Debuggable put: (1 bitShift: 25 - 1);
		at: #EnvCount put: (26 thru: 31)
]

{ #category : #initialization }
CompiledMethod class >> maxArgCount [
	^(2 raisedTo: ArgCount length) - 1
]

{ #category : #initialization }
CompiledMethod class >> maxBlockCount [
	^(2 raisedTo: BlockCount length) - 1
]

{ #category : #initialization }
CompiledMethod class >> maxTempCount [
	^(2 raisedTo: TempCount length) - 1
]

{ #category : #'instance creation' }
CompiledMethod class >> new: anInteger [
	| cm |
	cm := super new: anInteger.
	^cm initialize
]

{ #category : #comparing }
CompiledMethod >> ~ aCompiledMethod [
	self literals = aCompiledMethod literals ifFalse: [^false].
	^astcodes = aCompiledMethod astcodes
]

{ #category : #comparing }
CompiledMethod >> = anObject [
	^self == anObject
]

{ #category : #queries }
CompiledMethod >> addSymbolsIn: anArray to: aSet [
	anArray do: [:elem | 
		elem isSymbol
			ifTrue: [aSet add: elem]
			ifFalse: [elem class == Array ifTrue: [self addSymbolsIn: elem to: aSet]]]
]

{ #category : #accessing }
CompiledMethod >> argumentCount [
	^format bitsAt: ArgCount
]

{ #category : #accessing }
CompiledMethod >> argumentCount: anInteger [
	format := format bitsAt: ArgCount put: anInteger
]

{ #category : #converting }
CompiledMethod >> asOverridden [
	^self
]

{ #category : #accessing }
CompiledMethod >> blockCount [
	^format bitsAt: BlockCount
]

{ #category : #accessing }
CompiledMethod >> blockCount: anInteger [
	format := format bitsAt: BlockCount put: anInteger
]

{ #category : #enumerating }
CompiledMethod >> blocks [
	self hasBlocks ifFalse: [^#()].
	^self select: [:literal | literal isBlock]
]

{ #category : #enumerating }
CompiledMethod >> blocksDo: aBlock [
	self
		select: [:b | b isBlock and: [b method == self]]
		thenDo: [:b | aBlock evaluateWith: b]
]

{ #category : #accessing }
CompiledMethod >> astcodes [
	^astcodes
]

{ #category : #accessing }
CompiledMethod >> astcodes: aByteArray [
	astcodes := aByteArray
]

{ #category : #testing }
CompiledMethod >> canBeInstalled [
	^self isExpression not
]

{ #category : #accessing }
CompiledMethod >> classBinding [
	^class
]

{ #category : #accessing }
CompiledMethod >> classBinding: aClass [
	class := aClass
]

{ #category : #queries }
CompiledMethod >> currentVersion [
	^class compiledMethodAt: selector
]

{ #category : #accessing }
CompiledMethod >> environmentCount [
	^format bitsAt: EnvCount
]

{ #category : #accessing }
CompiledMethod >> environmentCount: anInteger [
	format bitsAt: EnvCount put: anInteger
]

{ #category : #accessing }
CompiledMethod >> executableCode [
	^optimizedCode
]

{ #category : #evaluation }
CompiledMethod >> executeOn: receiver withArguments: anArray [
	| size |
	self prepareForExecution.
	size := anArray basicSize.
	self argumentCount = size ifFalse: [^self error: 'incorrect arity'].
	anArray _expandInStackSized: size.
	^receiver _invoke: self validOptimizedCodeAddress _asNative
]

{ #category : #accessing }
CompiledMethod >> format [
	^format
]

{ #category : #accessing }
CompiledMethod >> format: anInteger [
	format := anInteger
]

{ #category : #testing }
CompiledMethod >> hasBlocks [
	^self blockCount > 0
]

{ #category : #services }
CompiledMethod >> hasEnvironment [
	^self environmentCount > 0
]

{ #category : #comparing }
CompiledMethod >> hash [
	^selector hashWith: class
]

{ #category : #accessing }
CompiledMethod >> hasOptimizedCode [
	^optimizedCode != nil
]

{ #category : #initialization }
CompiledMethod >> initialize [
	super initialize.
	format := 0
]

{ #category : #actions }
CompiledMethod >> install [
	class addSelector: selector withMethod: self
]

{ #category : #accessing }
CompiledMethod >> invalidateOptimizedCode [
	optimizedCode := nil.
	self blocksDo: [:b | b invalidateOptimizedCode]
]

{ #category : #testing }
CompiledMethod >> isCallback [
	^false
]

{ #category : #testing }
CompiledMethod >> isCompiledMethod [
	^true
]

{ #category : #testing }
CompiledMethod >> isCurrentVersion [
	^class notNil and: [self == (class compiledMethodAt: selector)]
]

{ #category : #testing }
CompiledMethod >> isDebuggable [
	^format isOnBit: Debuggable
]

{ #category : #accessing }
CompiledMethod >> isDoit [
	^false
]

{ #category : #testing }
CompiledMethod >> isExpression [
	^false
]

{ #category : #testing }
CompiledMethod >> isFFIMethod [
	^false
]

{ #category : #unclassified }
CompiledMethod >> isNativized [
	^false == (optimizedCode == nil)
]

{ #category : #testing }
CompiledMethod >> isOverridden [
	^false
]

{ #category : #accessing }
CompiledMethod >> literalIndexFrom: grossIndex [
	| instVars index |
	grossIndex _isSmallInteger ifFalse: [^self outOfBoundsIndex: grossIndex].
	instVars := self class instSize.
	(1 <= grossIndex and: [grossIndex <= (self _size - instVars)])
		ifFalse: [^self outOfBoundsIndex: grossIndex].
	index := grossIndex + instVars.
	^index
]

{ #category : #accessing }
CompiledMethod >> literals [
	^Array withAll: self
]

{ #category : #accessing }
CompiledMethod >> method [
	^self
]

{ #category : #accessing }
CompiledMethod >> optimizedCode [
	^optimizedCode
]

{ #category : #accessing }
CompiledMethod >> optimizedCode: anObject [
	code method: self.
	optimizedCode := anObject
]

{ #category : #accessing }
CompiledMethod >> optimizedCodeAddress [
	self prepareForExecution.
	^optimizedCode optimizedCodeAddress
]

{ #category : #copying }
CompiledMethod >> postCopy [
	super postCopy.
	self
		withIndexDo: [:b :i | | c |
			b isBlock ifTrue: [
				c := b copy method: self.
				self at: i put: c]];
		updateOptimizedCode
]

{ #category : #unclassified }
CompiledMethod >> prepareForExecution [
	self isNativized ifFalse: [Kernel prepareForExecution: self].
]

{ #category : #accessing }
CompiledMethod >> primitiveNumber [
	^0
]

{ #category : #printing }
CompiledMethod >> printOn: aStream [
	aStream
		print: class;
		nextPutAll: '>>';
		print: selector
]

{ #category : #accessing }
CompiledMethod >> selector [
	^selector
]

{ #category : #accessing }
CompiledMethod >> selector: aSymbol [
	selector := aSymbol.
	optimizedCode notNil ifTrue: [self invalidateOptimizedCode; nativize]
]

{ #category : #accessing }
CompiledMethod >> selectorAt: index [
	^self at: self size - index + 1
]

{ #category : #accessing }
CompiledMethod >> sendSites [
	^optimizedCode sendSites
]

{ #category : #'source code support' }
CompiledMethod >> sourceObject [
	^source
]

{ #category : #'source code support' }
CompiledMethod >> sourceObject: aString [
	source := aString
]

{ #category : #accessing }
CompiledMethod >> tempCount [
	^format bitsAt: TempCount
]

{ #category : #accessing }
CompiledMethod >> tempCount: anInteger [
	format := format bitsAt: TempCount put: anInteger
]

{ #category : #accessing }
CompiledMethod >> timestamp [
	| s |
	s := self sourceReference.
	^(s respondsTo: #timestamp) ifTrue: [s timestamp]
]

{ #category : #accessing }
CompiledMethod >> updateOptimizedCode [
	optimizedCode ifNil: [^self].
	self invalidateOptimizedCode; prepareForExecution
]

{ #category : #unclassified }
CompiledMethod >> validOptimizedCodeAddress [
	^optimizedCode code _asSmallInteger
]

