# This module supplies the **Model** class for the **im.js**
# web-service client.
#
# Models are representations of the descriptions of the data
# available within an intermine application.
#
# This library is designed to be compatible with both node.js
# and browsers.

IS_NODE = typeof exports isnt 'undefined'

__root__ = exports ? this

if IS_NODE
    intermine       = exports
    {_}             = require 'underscore'
    {Deferred}  = $ = require 'underscore.deferred'
    {Table}         = require './table'
    {PathInfo}      = require './path'
    {omap}          = require('./util')
else
    {_}             = __root__
    {Deferred} = $  = __root__.jQuery
    intermine       = (__root__.intermine ?= {})
    {Table, PathInfo} = intermine
    {omap}          = intermine.funcutils

# Lift classes to Tables
liftToTable = omap (k, v) -> [k, new Table(v)]

class Model

    constructor: ({@name, classes}) ->
        @classes = liftToTable classes

    getPathInfo: (path, subcls) -> PathInfo.parse @, path, subcls

    # Get a list that contains all the names of the 
    # subclasses of this class, as well as itself.
    getSubclassesOf: (cls) ->
        clazz = if (cls and cls.name) then cls else @classes[cls]
        unless clazz?
            throw new Error("#{ cls } is not a table")
        ret = [clazz.name]
        for _, cd of @classes
            if clazz.name in cd.superClasses
                ret = ret.concat(@getSubclassesOf cd)
        return ret

    getAncestorsOf: (cls) ->
        clazz = if (cls and cls.name) then cls else @classes[cls]
        unless clazz?
            throw new Error("#{ cls } is not a table")
        ancestors = clazz.superClasses.slice()
        for superC in clazz.superClasses
            ancestors.push @getAncestorsOf superC
        _.flatten ancestors

    findSharedAncestor: (classA, classB) =>
        if classB is null or classA is null or classA is classB
            return null
        a_ancestry = @getAncestorsOf classA
        b_ancestry = @getAncestorsOf classB
        if classB in a_ancestry
            return classB
        if classA in b_ancestry
            return classA
        return _.intersection(a_ancestry, b_ancestry).shift()

    findCommonType: (xs) -> xs.reduce @findSharedAncestor

Model::makePath = Model::getPathInfo
Model::findCommonTypeOfMultipleClasses = Model::findCommonType # API preserving alias.

# Static constructor.
Model.load = (data) -> new Model(data)

Model.NUMERIC_TYPES = ["int", "Integer", "double", "Double", "float", "Float"]
Model.INTEGRAL_TYPES = ["int", "Integer"]
Model.BOOLEAN_TYPES = ["boolean", "Boolean"]

intermine.Model = Model

