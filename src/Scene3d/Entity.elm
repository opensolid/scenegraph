module Scene3d.Entity exposing
    ( Entity
    , block
    , cone
    , cylinder
    , empty
    , group
    , lineSegment
    , mesh
    , mirrorAcross
    , placeIn
    , point
    , quad
    , relativeTo
    , rotateAround
    , scaleAbout
    , shadow
    , sphere
    , translateBy
    , translateIn
    , triangle
    )

import Angle exposing (Angle)
import Axis3d exposing (Axis3d)
import Block3d exposing (Block3d)
import BoundingBox3d exposing (BoundingBox3d)
import Cone3d exposing (Cone3d)
import Cylinder3d exposing (Cylinder3d)
import Direction3d exposing (Direction3d)
import Float.Extra as Float
import Frame3d exposing (Frame3d)
import Geometry.Interop.LinearAlgebra.Point3d as Point3d
import Length exposing (Length, Meters)
import LineSegment3d exposing (LineSegment3d)
import Luminance exposing (Luminance)
import Math.Matrix4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Math.Vector3 exposing (Vec3)
import Math.Vector4 exposing (Vec4)
import Pixels exposing (Pixels)
import Plane3d exposing (Plane3d)
import Point3d exposing (Point3d)
import Quantity exposing (Quantity(..), Unitless)
import Scene3d.Material as Material exposing (Material)
import Scene3d.Mesh exposing (Mesh, Shadow)
import Scene3d.Primitives as Primitives
import Scene3d.Transformation as Transformation exposing (Transformation)
import Scene3d.Types as Types
    exposing
        ( BackFaceSetting(..)
        , Bounds
        , LinearRgb(..)
        , Material(..)
        , Node(..)
        , NormalMap(..)
        , PlainVertex
        , Texture(..)
        , VertexWithNormal
        , VertexWithUv
        )
import Scene3d.UnoptimizedShaders as Shaders
import Sphere3d exposing (Sphere3d)
import Triangle3d exposing (Triangle3d)
import Vector3d exposing (Vector3d)
import WebGL
import WebGL.Settings
import WebGL.Settings.StencilTest as StencilTest
import WebGL.Texture


type alias Entity coordinates =
    Types.Entity coordinates


empty : Entity coordinates
empty =
    Types.Entity EmptyNode


mesh : Material coordinates attributes -> Mesh coordinates attributes -> Entity coordinates
mesh givenMaterial givenMesh =
    case givenMaterial of
        Types.UnlitMaterial _ (Types.Constant color) ->
            case givenMesh of
                Types.EmptyMesh ->
                    empty

                Types.Triangles boundingBox _ webGLMesh backFaceSetting ->
                    constantMesh color (toBounds boundingBox) webGLMesh backFaceSetting

                Types.Facets boundingBox _ webGLMesh backFaceSetting ->
                    constantMesh color (toBounds boundingBox) webGLMesh backFaceSetting

                Types.Indexed boundingBox _ webGLMesh backFaceSetting ->
                    constantMesh color (toBounds boundingBox) webGLMesh backFaceSetting

                Types.MeshWithNormals boundingBox _ webGLMesh backFaceSetting ->
                    constantMesh color (toBounds boundingBox) webGLMesh backFaceSetting

                Types.MeshWithUvs boundingBox _ webGLMesh backFaceSetting ->
                    constantMesh color (toBounds boundingBox) webGLMesh backFaceSetting

                Types.MeshWithNormalsAndUvs boundingBox _ webGLMesh backFaceSetting ->
                    constantMesh color (toBounds boundingBox) webGLMesh backFaceSetting

                Types.MeshWithTangents boundingBox _ webGLMesh backFaceSetting ->
                    constantMesh color (toBounds boundingBox) webGLMesh backFaceSetting

                Types.LineSegments boundingBox _ webGLMesh ->
                    constantMesh color (toBounds boundingBox) webGLMesh KeepBackFaces

                Types.Polyline boundingBox _ webGLMesh ->
                    constantMesh color (toBounds boundingBox) webGLMesh KeepBackFaces

                Types.Points boundingBox radius _ webGLMesh ->
                    constantPointMesh color radius (toBounds boundingBox) webGLMesh

        Types.UnlitMaterial Types.UseMeshUvs (Types.Texture { data }) ->
            case givenMesh of
                Types.EmptyMesh ->
                    empty

                Types.Triangles _ _ _ _ ->
                    empty

                Types.Facets _ _ _ _ ->
                    empty

                Types.Indexed _ _ _ _ ->
                    empty

                Types.MeshWithNormals _ _ _ _ ->
                    empty

                Types.MeshWithUvs boundingBox _ webGLMesh backFaceSetting ->
                    colorTextureMesh data (toBounds boundingBox) webGLMesh backFaceSetting

                Types.MeshWithNormalsAndUvs boundingBox _ webGLMesh backFaceSetting ->
                    colorTextureMesh data (toBounds boundingBox) webGLMesh backFaceSetting

                Types.MeshWithTangents boundingBox _ webGLMesh backFaceSetting ->
                    colorTextureMesh data (toBounds boundingBox) webGLMesh backFaceSetting

                Types.LineSegments _ _ _ ->
                    empty

                Types.Polyline _ _ _ ->
                    empty

                Types.Points _ _ _ _ ->
                    empty

        Types.EmissiveMaterial _ (Types.Constant (LinearRgb emissiveColor)) backlight ->
            case givenMesh of
                Types.EmptyMesh ->
                    empty

                Types.Triangles boundingBox _ webGLMesh backFaceSetting ->
                    emissiveMesh emissiveColor backlight (toBounds boundingBox) webGLMesh backFaceSetting

                Types.Facets boundingBox _ webGLMesh backFaceSetting ->
                    emissiveMesh emissiveColor backlight (toBounds boundingBox) webGLMesh backFaceSetting

                Types.Indexed boundingBox _ webGLMesh backFaceSetting ->
                    emissiveMesh emissiveColor backlight (toBounds boundingBox) webGLMesh backFaceSetting

                Types.MeshWithNormals boundingBox _ webGLMesh backFaceSetting ->
                    emissiveMesh emissiveColor backlight (toBounds boundingBox) webGLMesh backFaceSetting

                Types.MeshWithUvs boundingBox _ webGLMesh backFaceSetting ->
                    emissiveMesh emissiveColor backlight (toBounds boundingBox) webGLMesh backFaceSetting

                Types.MeshWithNormalsAndUvs boundingBox _ webGLMesh backFaceSetting ->
                    emissiveMesh emissiveColor backlight (toBounds boundingBox) webGLMesh backFaceSetting

                Types.MeshWithTangents boundingBox _ webGLMesh backFaceSetting ->
                    emissiveMesh emissiveColor backlight (toBounds boundingBox) webGLMesh backFaceSetting

                Types.LineSegments boundingBox _ webGLMesh ->
                    emissiveMesh emissiveColor backlight (toBounds boundingBox) webGLMesh KeepBackFaces

                Types.Polyline boundingBox _ webGLMesh ->
                    emissiveMesh emissiveColor backlight (toBounds boundingBox) webGLMesh KeepBackFaces

                Types.Points boundingBox radius _ webGLMesh ->
                    emissivePointMesh emissiveColor backlight radius (toBounds boundingBox) webGLMesh

        Types.EmissiveMaterial Types.UseMeshUvs (Types.Texture { data }) backlight ->
            case givenMesh of
                Types.EmptyMesh ->
                    empty

                Types.Triangles _ _ _ _ ->
                    empty

                Types.Facets _ _ _ _ ->
                    empty

                Types.Indexed _ _ _ _ ->
                    empty

                Types.MeshWithNormals _ _ _ _ ->
                    empty

                Types.MeshWithUvs boundingBox _ webGLMesh backFaceSetting ->
                    texturedEmissiveMesh data backlight (toBounds boundingBox) webGLMesh backFaceSetting

                Types.MeshWithNormalsAndUvs boundingBox _ webGLMesh backFaceSetting ->
                    texturedEmissiveMesh data backlight (toBounds boundingBox) webGLMesh backFaceSetting

                Types.MeshWithTangents boundingBox _ webGLMesh backFaceSetting ->
                    texturedEmissiveMesh data backlight (toBounds boundingBox) webGLMesh backFaceSetting

                Types.LineSegments _ _ _ ->
                    empty

                Types.Polyline _ _ _ ->
                    empty

                Types.Points _ _ _ _ ->
                    empty

        Types.LambertianMaterial Types.UseMeshUvs materialColorTexture normalMapTexture ->
            case resolveLambertian materialColorTexture normalMapTexture of
                ConstantLambertianMaterial (LinearRgb materialColor) ->
                    case givenMesh of
                        Types.EmptyMesh ->
                            empty

                        Types.Triangles _ _ _ _ ->
                            empty

                        Types.Facets boundingBox _ webGLMesh cullBackFaces ->
                            lambertianMesh materialColor (toBounds boundingBox) webGLMesh cullBackFaces

                        Types.Indexed _ _ _ _ ->
                            empty

                        Types.MeshWithNormals boundingBox _ webGLMesh cullBackFaces ->
                            lambertianMesh materialColor (toBounds boundingBox) webGLMesh cullBackFaces

                        Types.MeshWithUvs _ _ _ _ ->
                            empty

                        Types.MeshWithNormalsAndUvs boundingBox _ webGLMesh cullBackFaces ->
                            lambertianMesh materialColor (toBounds boundingBox) webGLMesh cullBackFaces

                        Types.MeshWithTangents boundingBox _ webGLMesh cullBackFaces ->
                            lambertianMesh materialColor (toBounds boundingBox) webGLMesh cullBackFaces

                        Types.LineSegments _ _ _ ->
                            empty

                        Types.Polyline _ _ _ ->
                            empty

                        Types.Points _ _ _ _ ->
                            empty

                TexturedLambertianMaterial ( materialColorData, constantMaterialColor ) ( normalMapData, useNormalMap ) ->
                    case givenMesh of
                        Types.EmptyMesh ->
                            empty

                        Types.Triangles _ _ _ _ ->
                            empty

                        Types.Facets _ _ _ _ ->
                            empty

                        Types.Indexed _ _ _ _ ->
                            empty

                        Types.MeshWithNormals _ _ _ _ ->
                            empty

                        Types.MeshWithUvs _ _ _ _ ->
                            empty

                        Types.MeshWithNormalsAndUvs boundingBox _ webGLMesh cullBackFaces ->
                            texturedLambertianMesh materialColorData (toBounds boundingBox) webGLMesh cullBackFaces

                        Types.MeshWithTangents boundingBox _ webGLMesh cullBackFaces ->
                            normalMappedLambertianMesh materialColorData normalMapData useNormalMap (toBounds boundingBox) webGLMesh cullBackFaces

                        Types.LineSegments _ _ _ ->
                            empty

                        Types.Polyline _ _ _ ->
                            empty

                        Types.Points _ _ _ _ ->
                            empty

        Types.PbrMaterial Types.UseMeshUvs baseColorTexture roughnessTexture metallicTexture normalMapTexture ->
            case resolvePbr baseColorTexture roughnessTexture metallicTexture normalMapTexture of
                ConstantPbrMaterial (LinearRgb baseColor) roughness metallic ->
                    case givenMesh of
                        Types.EmptyMesh ->
                            empty

                        Types.Triangles _ _ _ _ ->
                            empty

                        Types.Facets boundingBox _ webGLMesh backFaceSetting ->
                            physicalMesh
                                baseColor
                                roughness
                                metallic
                                (toBounds boundingBox)
                                webGLMesh
                                backFaceSetting

                        Types.Indexed _ _ _ _ ->
                            empty

                        Types.MeshWithNormals boundingBox _ webGLMesh backFaceSetting ->
                            physicalMesh
                                baseColor
                                roughness
                                metallic
                                (toBounds boundingBox)
                                webGLMesh
                                backFaceSetting

                        Types.MeshWithUvs _ _ _ _ ->
                            empty

                        Types.MeshWithNormalsAndUvs boundingBox _ webGLMesh backFaceSetting ->
                            physicalMesh
                                baseColor
                                roughness
                                metallic
                                (toBounds boundingBox)
                                webGLMesh
                                backFaceSetting

                        Types.MeshWithTangents boundingBox _ webGLMesh backFaceSetting ->
                            physicalMesh
                                baseColor
                                roughness
                                metallic
                                (toBounds boundingBox)
                                webGLMesh
                                backFaceSetting

                        Types.LineSegments _ _ _ ->
                            empty

                        Types.Polyline _ _ _ ->
                            empty

                        Types.Points _ _ _ _ ->
                            empty

                TexturedPbrMaterial ( baseColorData, constantBaseColor ) ( roughnessData, constantRoughness ) ( metallicData, constantMetallic ) ( normalMapData, useNormalMap ) ->
                    case givenMesh of
                        Types.EmptyMesh ->
                            empty

                        Types.Triangles _ _ _ _ ->
                            empty

                        Types.Facets _ _ _ _ ->
                            empty

                        Types.Indexed _ _ _ _ ->
                            empty

                        Types.MeshWithNormals _ _ _ _ ->
                            empty

                        Types.MeshWithUvs _ _ _ _ ->
                            empty

                        Types.MeshWithNormalsAndUvs boundingBox _ webGLMesh backFaceSetting ->
                            texturedPhysicalMesh
                                baseColorData
                                constantBaseColor
                                roughnessData
                                constantRoughness
                                metallicData
                                constantMetallic
                                (toBounds boundingBox)
                                webGLMesh
                                backFaceSetting

                        Types.MeshWithTangents boundingBox _ webGLMesh backFaceSetting ->
                            normalMappedPhysicalMesh
                                baseColorData
                                constantBaseColor
                                roughnessData
                                constantRoughness
                                metallicData
                                constantMetallic
                                normalMapData
                                useNormalMap
                                (toBounds boundingBox)
                                webGLMesh
                                backFaceSetting

                        Types.LineSegments _ _ _ ->
                            empty

                        Types.Polyline _ _ _ ->
                            empty

                        Types.Points _ _ _ _ ->
                            empty


type ResolvedLambertianMaterial
    = ConstantLambertianMaterial (LinearRgb Unitless)
    | TexturedLambertianMaterial ( WebGL.Texture.Texture, Vec4 ) ( WebGL.Texture.Texture, Float )


type ResolvedPbrMaterial
    = ConstantPbrMaterial (LinearRgb Unitless) Float Float
    | TexturedPbrMaterial ( WebGL.Texture.Texture, Vec4 ) ( WebGL.Texture.Texture, Vec2 ) ( WebGL.Texture.Texture, Vec2 ) ( WebGL.Texture.Texture, Float )


enabledFloat : Float -> Vec2
enabledFloat value =
    Math.Vector2.vec2 value 1


zeroVec2 : Vec2
zeroVec2 =
    Math.Vector2.vec2 0 0


zeroVec4 : Vec4
zeroVec4 =
    Math.Vector4.vec4 0 0 0 0


enabledVec3 : Vec3 -> Vec4
enabledVec3 vector =
    Math.Vector4.vec4
        (Math.Vector3.getX vector)
        (Math.Vector3.getY vector)
        (Math.Vector3.getZ vector)
        1


vec3Tuple : WebGL.Texture.Texture -> Texture (LinearRgb Unitless) -> ( WebGL.Texture.Texture, Vec4 )
vec3Tuple fallbackData texture =
    case texture of
        Types.Constant (LinearRgb baseColor) ->
            ( fallbackData, enabledVec3 baseColor )

        Types.Texture { data } ->
            ( data, zeroVec4 )


floatTuple : WebGL.Texture.Texture -> Texture Float -> ( WebGL.Texture.Texture, Vec2 )
floatTuple fallbackData texture =
    case texture of
        Types.Constant value ->
            ( fallbackData, enabledFloat value )

        Types.Texture { data } ->
            ( data, zeroVec2 )


normalMapTuple : WebGL.Texture.Texture -> Texture NormalMap -> ( WebGL.Texture.Texture, Float )
normalMapTuple fallbackData channel =
    case channel of
        Types.Constant Types.VerticalNormal ->
            ( fallbackData, 0.0 )

        Types.Texture { data } ->
            ( data, 1.0 )


type Tuple4 a b c d
    = Tuple4 a b c d


resolvePbr : Texture (LinearRgb Unitless) -> Texture Float -> Texture Float -> Texture NormalMap -> ResolvedPbrMaterial
resolvePbr baseColorTexture roughnessTexture metallicTexture normalMapTexture =
    case Tuple4 baseColorTexture roughnessTexture metallicTexture normalMapTexture of
        Tuple4 (Types.Constant baseColor) (Types.Constant roughness) (Types.Constant metallic) (Types.Constant Types.VerticalNormal) ->
            ConstantPbrMaterial baseColor roughness metallic

        Tuple4 (Types.Texture { data }) _ _ _ ->
            TexturedPbrMaterial
                ( data, zeroVec4 )
                (floatTuple data roughnessTexture)
                (floatTuple data metallicTexture)
                (normalMapTuple data normalMapTexture)

        Tuple4 _ (Types.Texture { data }) _ _ ->
            TexturedPbrMaterial
                (vec3Tuple data baseColorTexture)
                ( data, zeroVec2 )
                (floatTuple data metallicTexture)
                (normalMapTuple data normalMapTexture)

        Tuple4 _ _ (Types.Texture { data }) _ ->
            TexturedPbrMaterial
                (vec3Tuple data baseColorTexture)
                (floatTuple data roughnessTexture)
                ( data, zeroVec2 )
                (normalMapTuple data normalMapTexture)

        Tuple4 _ _ _ (Types.Texture { data }) ->
            TexturedPbrMaterial
                (vec3Tuple data baseColorTexture)
                (floatTuple data roughnessTexture)
                (floatTuple data metallicTexture)
                ( data, 1.0 )


resolveLambertian : Texture (LinearRgb Unitless) -> Texture NormalMap -> ResolvedLambertianMaterial
resolveLambertian materialColorTexture normalMapTexture =
    case ( materialColorTexture, normalMapTexture ) of
        ( Types.Constant materialColor, Types.Constant Types.VerticalNormal ) ->
            ConstantLambertianMaterial materialColor

        ( Types.Texture { data }, _ ) ->
            TexturedLambertianMaterial
                ( data, zeroVec4 )
                (normalMapTuple data normalMapTexture)

        ( _, Types.Texture { data } ) ->
            TexturedLambertianMaterial
                (vec3Tuple data materialColorTexture)
                (normalMapTuple data normalMapTexture)


point : Quantity Float Pixels -> Material.Plain coordinates -> Point3d Meters coordinates -> Entity coordinates
point givenRadius givenMaterial givenPoint =
    let
        boundingBox =
            BoundingBox3d.singleton givenPoint

        bounds =
            toBounds boundingBox
    in
    case givenMaterial of
        Types.UnlitMaterial _ (Types.Constant color) ->
            Types.Entity <|
                PointNode bounds <|
                    \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                        WebGL.entityWith
                            settings
                            Shaders.singlePointVertex
                            Shaders.constantPointFragment
                            dummyVertex
                            { pointPosition = Point3d.toVec3 givenPoint
                            , pointRadius = Pixels.inPixels givenRadius
                            , constantColor = color
                            , sceneProperties = sceneProperties
                            , modelScale = modelScale
                            , modelMatrix = modelMatrix
                            , viewMatrix = viewMatrix
                            , projectionMatrix = projectionMatrix
                            }

        Types.UnlitMaterial _ (Types.Texture { data }) ->
            empty

        Types.EmissiveMaterial _ (Types.Constant (LinearRgb color)) backlight ->
            Types.Entity <|
                PointNode bounds <|
                    \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                        WebGL.entityWith
                            settings
                            Shaders.singlePointVertex
                            Shaders.emissivePointFragment
                            dummyVertex
                            { pointPosition = Point3d.toVec3 givenPoint
                            , pointRadius = Pixels.inPixels givenRadius
                            , sceneProperties = sceneProperties
                            , emissiveColor = Math.Vector3.scale (Luminance.inNits backlight) color
                            , modelScale = modelScale
                            , modelMatrix = modelMatrix
                            , viewMatrix = viewMatrix
                            , projectionMatrix = projectionMatrix
                            }

        Types.EmissiveMaterial _ (Types.Texture _) _ ->
            empty

        Types.LambertianMaterial _ _ _ ->
            empty

        Types.PbrMaterial _ _ _ _ _ ->
            empty


dummyVertex : WebGL.Mesh { dummyAttribute : Float }
dummyVertex =
    WebGL.points [ { dummyAttribute = 1 } ]


lineSegment : Material.Plain coordinates -> LineSegment3d Meters coordinates -> Entity coordinates
lineSegment givenMaterial givenLineSegment =
    let
        boundingBox =
            LineSegment3d.boundingBox givenLineSegment

        bounds =
            toBounds boundingBox

        ( p1, p2 ) =
            LineSegment3d.endpoints givenLineSegment
    in
    case givenMaterial of
        Types.UnlitMaterial _ (Types.Constant color) ->
            Types.Entity <|
                MeshNode bounds <|
                    \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                        WebGL.entityWith
                            settings
                            Shaders.lineSegmentVertex
                            Shaders.constantFragment
                            lineSegmentVertices
                            { lineSegmentStartPoint = Point3d.toVec3 p1
                            , lineSegmentEndPoint = Point3d.toVec3 p2
                            , constantColor = color
                            , sceneProperties = sceneProperties
                            , modelScale = modelScale
                            , modelMatrix = modelMatrix
                            , viewMatrix = viewMatrix
                            , projectionMatrix = projectionMatrix
                            }

        Types.UnlitMaterial Types.UseMeshUvs (Types.Texture { data }) ->
            empty

        Types.EmissiveMaterial _ (Types.Constant (LinearRgb color)) backlight ->
            Types.Entity <|
                MeshNode bounds <|
                    \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                        WebGL.entityWith
                            settings
                            Shaders.lineSegmentVertex
                            Shaders.emissiveFragment
                            lineSegmentVertices
                            { lineSegmentStartPoint = Point3d.toVec3 p1
                            , lineSegmentEndPoint = Point3d.toVec3 p2
                            , sceneProperties = sceneProperties
                            , modelScale = modelScale
                            , emissiveColor = Math.Vector3.scale (Luminance.inNits backlight) color
                            , modelMatrix = modelMatrix
                            , viewMatrix = viewMatrix
                            , projectionMatrix = projectionMatrix
                            }

        Types.EmissiveMaterial _ (Types.Texture _) _ ->
            empty

        Types.LambertianMaterial _ _ _ ->
            empty

        Types.PbrMaterial _ _ _ _ _ ->
            empty


lineSegmentVertices : WebGL.Mesh { lineSegmentVertex : Float }
lineSegmentVertices =
    WebGL.lines [ ( { lineSegmentVertex = 0 }, { lineSegmentVertex = 1 } ) ]


triangle :
    Bool
    -> Bool
    -> Material.Uniform coordinates
    -> Triangle3d Meters coordinates
    -> Entity coordinates
triangle renderObject renderShadow givenMaterial givenTriangle =
    let
        meshEntity =
            triangleMesh givenMaterial givenTriangle
    in
    case ( renderObject, renderShadow ) of
        ( True, True ) ->
            group [ meshEntity, triangleShadow givenTriangle ]

        ( True, False ) ->
            meshEntity

        ( False, True ) ->
            triangleShadow givenTriangle

        ( False, False ) ->
            empty


triangleVertices : WebGL.Mesh { triangleVertex : Float }
triangleVertices =
    WebGL.triangles [ ( { triangleVertex = 0 }, { triangleVertex = 1 }, { triangleVertex = 2 } ) ]


triangleVertexPositions : Triangle3d Meters coordinates -> Mat4
triangleVertexPositions givenTriangle =
    let
        ( firstPoint, secondPoint, thirdPoint ) =
            Triangle3d.vertices givenTriangle

        p1 =
            Point3d.toMeters firstPoint

        p2 =
            Point3d.toMeters secondPoint

        p3 =
            Point3d.toMeters thirdPoint
    in
    Math.Matrix4.fromRecord
        { m11 = p1.x
        , m21 = p1.y
        , m31 = p1.z
        , m41 = 0
        , m12 = p2.x
        , m22 = p2.y
        , m32 = p2.z
        , m42 = 0
        , m13 = p3.x
        , m23 = p3.y
        , m33 = p3.z
        , m43 = 0
        , m14 = 0
        , m24 = 0
        , m34 = 0
        , m44 = 0
        }


quad :
    Bool
    -> Bool
    -> Material.Textured coordinates
    -> Point3d Meters coordinates
    -> Point3d Meters coordinates
    -> Point3d Meters coordinates
    -> Point3d Meters coordinates
    -> Entity coordinates
quad renderObject renderShadow givenMaterial firstPoint secondPoint thirdPoint fourthPoint =
    let
        meshEntity =
            quadMesh givenMaterial firstPoint secondPoint thirdPoint fourthPoint
    in
    case ( renderObject, renderShadow ) of
        ( True, True ) ->
            group [ meshEntity, quadShadow firstPoint secondPoint thirdPoint fourthPoint ]

        ( True, False ) ->
            meshEntity

        ( False, True ) ->
            quadShadow firstPoint secondPoint thirdPoint fourthPoint

        ( False, False ) ->
            empty


quadVertices : WebGL.Mesh { quadVertex : Vec3 }
quadVertices =
    WebGL.triangleFan
        [ { quadVertex = Math.Vector3.vec3 0 0 0 }
        , { quadVertex = Math.Vector3.vec3 1 0 1 }
        , { quadVertex = Math.Vector3.vec3 1 1 2 }
        , { quadVertex = Math.Vector3.vec3 0 1 3 }
        ]


quadVertexPositions :
    Point3d Meters coordinates
    -> Point3d Meters coordinates
    -> Point3d Meters coordinates
    -> Point3d Meters coordinates
    -> Mat4
quadVertexPositions firstPoint secondPoint thirdPoint fourthPoint =
    let
        p1 =
            Point3d.toMeters firstPoint

        p2 =
            Point3d.toMeters secondPoint

        p3 =
            Point3d.toMeters thirdPoint

        p4 =
            Point3d.toMeters fourthPoint
    in
    Math.Matrix4.fromRecord
        { m11 = p1.x
        , m21 = p1.y
        , m31 = p1.z
        , m41 = 0
        , m12 = p2.x
        , m22 = p2.y
        , m32 = p2.z
        , m42 = 0
        , m13 = p3.x
        , m23 = p3.y
        , m33 = p3.z
        , m43 = 0
        , m14 = p4.x
        , m24 = p4.y
        , m34 = p4.z
        , m44 = 0
        }


toBounds : BoundingBox3d units coordinates -> Bounds
toBounds boundingBox =
    let
        ( Quantity xDimension, Quantity yDimension, Quantity zDimension ) =
            BoundingBox3d.dimensions boundingBox
    in
    { centerPoint = Point3d.unwrap (BoundingBox3d.centerPoint boundingBox)
    , halfX = xDimension / 2
    , halfY = yDimension / 2
    , halfZ = zDimension / 2
    }


triangleMesh : Material.Uniform coordinates -> Triangle3d Meters coordinates -> Entity coordinates
triangleMesh givenMaterial givenTriangle =
    let
        boundingBox =
            Triangle3d.boundingBox givenTriangle

        bounds =
            toBounds boundingBox
    in
    case givenMaterial of
        Types.UnlitMaterial _ (Types.Constant color) ->
            Types.Entity <|
                MeshNode bounds <|
                    \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                        WebGL.entityWith
                            (meshSettings isRightHanded Types.KeepBackFaces settings)
                            Shaders.plainTriangleVertex
                            Shaders.constantFragment
                            triangleVertices
                            { triangleVertexPositions = triangleVertexPositions givenTriangle
                            , constantColor = color
                            , sceneProperties = sceneProperties
                            , modelScale = modelScale
                            , modelMatrix = modelMatrix
                            , viewMatrix = viewMatrix
                            , projectionMatrix = projectionMatrix
                            }

        Types.UnlitMaterial Types.UseMeshUvs (Types.Texture { data }) ->
            empty

        Types.EmissiveMaterial _ (Types.Constant (LinearRgb emissiveColor)) backlight ->
            Types.Entity <|
                MeshNode bounds <|
                    \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                        WebGL.entityWith
                            (meshSettings isRightHanded Types.KeepBackFaces settings)
                            Shaders.plainTriangleVertex
                            Shaders.emissiveFragment
                            triangleVertices
                            { triangleVertexPositions = triangleVertexPositions givenTriangle
                            , emissiveColor = Math.Vector3.scale (Luminance.inNits backlight) emissiveColor
                            , sceneProperties = sceneProperties
                            , modelScale = modelScale
                            , modelMatrix = modelMatrix
                            , viewMatrix = viewMatrix
                            , projectionMatrix = projectionMatrix
                            }

        Types.EmissiveMaterial Types.UseMeshUvs (Types.Texture _) _ ->
            empty

        Types.LambertianMaterial Types.UseMeshUvs materialColorTexture normalMapTexture ->
            case resolveLambertian materialColorTexture normalMapTexture of
                ConstantLambertianMaterial (LinearRgb materialColor) ->
                    Types.Entity <|
                        MeshNode bounds <|
                            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix ( lights, enabledLights ) settings ->
                                WebGL.entityWith
                                    (meshSettings isRightHanded Types.KeepBackFaces settings)
                                    Shaders.smoothTriangleVertex
                                    Shaders.lambertianFragment
                                    triangleVertices
                                    { triangleVertexPositions = triangleVertexPositions givenTriangle
                                    , lights12 = lights.lights12
                                    , lights34 = lights.lights34
                                    , lights56 = lights.lights56
                                    , lights78 = lights.lights78
                                    , enabledLights = enabledLights
                                    , materialColor = materialColor
                                    , sceneProperties = sceneProperties
                                    , modelScale = modelScale
                                    , modelMatrix = modelMatrix
                                    , viewMatrix = viewMatrix
                                    , projectionMatrix = projectionMatrix
                                    }

                TexturedLambertianMaterial _ _ ->
                    empty

        Types.PbrMaterial Types.UseMeshUvs baseColorTexture roughnessTexture metallicTexture normalMapTexture ->
            case resolvePbr baseColorTexture roughnessTexture metallicTexture normalMapTexture of
                ConstantPbrMaterial (LinearRgb baseColor) roughness metallic ->
                    Types.Entity <|
                        MeshNode bounds <|
                            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix ( lights, enabledLights ) settings ->
                                WebGL.entityWith
                                    (meshSettings isRightHanded Types.KeepBackFaces settings)
                                    Shaders.smoothTriangleVertex
                                    Shaders.physicalFragment
                                    triangleVertices
                                    { triangleVertexPositions = triangleVertexPositions givenTriangle
                                    , lights12 = lights.lights12
                                    , lights34 = lights.lights34
                                    , lights56 = lights.lights56
                                    , lights78 = lights.lights78
                                    , enabledLights = enabledLights
                                    , baseColor = baseColor
                                    , roughness = roughness
                                    , metallic = metallic
                                    , sceneProperties = sceneProperties
                                    , modelScale = modelScale
                                    , modelMatrix = modelMatrix
                                    , viewMatrix = viewMatrix
                                    , projectionMatrix = projectionMatrix
                                    }

                TexturedPbrMaterial _ _ _ _ ->
                    empty


quadMesh :
    Material.Textured coordinates
    -> Point3d Meters coordinates
    -> Point3d Meters coordinates
    -> Point3d Meters coordinates
    -> Point3d Meters coordinates
    -> Entity coordinates
quadMesh givenMaterial firstPoint secondPoint thirdPoint fourthPoint =
    let
        boundingBox =
            BoundingBox3d.hull firstPoint [ secondPoint, thirdPoint, fourthPoint ]

        bounds =
            toBounds boundingBox
    in
    Types.Entity <|
        MeshNode bounds <|
            case givenMaterial of
                Types.UnlitMaterial _ (Types.Constant color) ->
                    \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                        WebGL.entityWith
                            (meshSettings isRightHanded Types.KeepBackFaces settings)
                            Shaders.plainQuadVertex
                            Shaders.constantFragment
                            quadVertices
                            { quadVertexPositions = quadVertexPositions firstPoint secondPoint thirdPoint fourthPoint
                            , constantColor = color
                            , sceneProperties = sceneProperties
                            , modelScale = modelScale
                            , modelMatrix = modelMatrix
                            , viewMatrix = viewMatrix
                            , projectionMatrix = projectionMatrix
                            }

                Types.UnlitMaterial Types.UseMeshUvs (Types.Texture { data }) ->
                    \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                        WebGL.entityWith
                            (meshSettings isRightHanded Types.KeepBackFaces settings)
                            Shaders.unlitQuadVertex
                            Shaders.colorTextureFragment
                            quadVertices
                            { quadVertexPositions = quadVertexPositions firstPoint secondPoint thirdPoint fourthPoint
                            , colorTexture = data
                            , sceneProperties = sceneProperties
                            , modelScale = modelScale
                            , modelMatrix = modelMatrix
                            , viewMatrix = viewMatrix
                            , projectionMatrix = projectionMatrix
                            }

                Types.EmissiveMaterial _ (Types.Constant (LinearRgb emissiveColor)) backlight ->
                    \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                        WebGL.entityWith
                            (meshSettings isRightHanded Types.KeepBackFaces settings)
                            Shaders.plainQuadVertex
                            Shaders.emissiveFragment
                            quadVertices
                            { quadVertexPositions = quadVertexPositions firstPoint secondPoint thirdPoint fourthPoint
                            , backlight = backlight
                            , emissiveColor = Math.Vector3.scale (Luminance.inNits backlight) emissiveColor
                            , sceneProperties = sceneProperties
                            , modelScale = modelScale
                            , modelMatrix = modelMatrix
                            , viewMatrix = viewMatrix
                            , projectionMatrix = projectionMatrix
                            }

                Types.EmissiveMaterial Types.UseMeshUvs (Types.Texture { data }) backlight ->
                    \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                        WebGL.entityWith
                            (meshSettings isRightHanded Types.KeepBackFaces settings)
                            Shaders.unlitQuadVertex
                            Shaders.emissiveTextureFragment
                            quadVertices
                            { quadVertexPositions = quadVertexPositions firstPoint secondPoint thirdPoint fourthPoint
                            , backlight = Luminance.inNits backlight
                            , colorTexture = data
                            , sceneProperties = sceneProperties
                            , modelScale = modelScale
                            , modelMatrix = modelMatrix
                            , viewMatrix = viewMatrix
                            , projectionMatrix = projectionMatrix
                            }

                Types.LambertianMaterial Types.UseMeshUvs materialColorTexture normalMapTexture ->
                    case resolveLambertian materialColorTexture normalMapTexture of
                        ConstantLambertianMaterial (LinearRgb materialColor) ->
                            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix ( lights, enabledLights ) settings ->
                                WebGL.entityWith
                                    (meshSettings isRightHanded Types.KeepBackFaces settings)
                                    Shaders.smoothQuadVertex
                                    Shaders.lambertianFragment
                                    quadVertices
                                    { quadVertexPositions = quadVertexPositions firstPoint secondPoint thirdPoint fourthPoint
                                    , lights12 = lights.lights12
                                    , lights34 = lights.lights34
                                    , lights56 = lights.lights56
                                    , lights78 = lights.lights78
                                    , enabledLights = enabledLights
                                    , materialColor = materialColor
                                    , sceneProperties = sceneProperties
                                    , modelScale = modelScale
                                    , modelMatrix = modelMatrix
                                    , viewMatrix = viewMatrix
                                    , projectionMatrix = projectionMatrix
                                    }

                        TexturedLambertianMaterial ( materialColorData, constantMaterialColor ) ( normalMapData, useNormalMap ) ->
                            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix ( lights, enabledLights ) settings ->
                                WebGL.entityWith
                                    (meshSettings isRightHanded Types.KeepBackFaces settings)
                                    Shaders.texturedQuadVertex
                                    Shaders.lambertianTextureFragment
                                    quadVertices
                                    { quadVertexPositions = quadVertexPositions firstPoint secondPoint thirdPoint fourthPoint
                                    , materialColorTexture = materialColorData
                                    , normalMapTexture = normalMapData
                                    , useNormalMap = useNormalMap
                                    , lights12 = lights.lights12
                                    , lights34 = lights.lights34
                                    , lights56 = lights.lights56
                                    , lights78 = lights.lights78
                                    , enabledLights = enabledLights
                                    , sceneProperties = sceneProperties
                                    , modelScale = modelScale
                                    , modelMatrix = modelMatrix
                                    , viewMatrix = viewMatrix
                                    , projectionMatrix = projectionMatrix
                                    }

                Types.PbrMaterial Types.UseMeshUvs baseColorTexture roughnessTexture metallicTexture normalMapTexture ->
                    case resolvePbr baseColorTexture roughnessTexture metallicTexture normalMapTexture of
                        ConstantPbrMaterial (LinearRgb baseColor) roughness metallic ->
                            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix ( lights, enabledLights ) settings ->
                                WebGL.entityWith
                                    (meshSettings isRightHanded Types.KeepBackFaces settings)
                                    Shaders.smoothQuadVertex
                                    Shaders.physicalFragment
                                    quadVertices
                                    { quadVertexPositions = quadVertexPositions firstPoint secondPoint thirdPoint fourthPoint
                                    , lights12 = lights.lights12
                                    , lights34 = lights.lights34
                                    , lights56 = lights.lights56
                                    , lights78 = lights.lights78
                                    , enabledLights = enabledLights
                                    , baseColor = baseColor
                                    , roughness = roughness
                                    , metallic = metallic
                                    , sceneProperties = sceneProperties
                                    , modelScale = modelScale
                                    , modelMatrix = modelMatrix
                                    , viewMatrix = viewMatrix
                                    , projectionMatrix = projectionMatrix
                                    }

                        TexturedPbrMaterial ( baseColorData, constantBaseColor ) ( roughnessData, constantRoughness ) ( metallicData, constantMetallic ) ( normalMapData, useNormalMap ) ->
                            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix ( lights, enabledLights ) settings ->
                                WebGL.entityWith
                                    (meshSettings isRightHanded Types.KeepBackFaces settings)
                                    Shaders.texturedQuadVertex
                                    Shaders.physicalTexturesFragment
                                    quadVertices
                                    { quadVertexPositions = quadVertexPositions firstPoint secondPoint thirdPoint fourthPoint
                                    , lights12 = lights.lights12
                                    , lights34 = lights.lights34
                                    , lights56 = lights.lights56
                                    , lights78 = lights.lights78
                                    , enabledLights = enabledLights
                                    , baseColorTexture = baseColorData
                                    , constantBaseColor = constantBaseColor
                                    , roughnessTexture = roughnessData
                                    , constantRoughness = constantRoughness
                                    , metallicTexture = metallicData
                                    , constantMetallic = constantMetallic
                                    , normalMapTexture = normalMapData
                                    , useNormalMap = useNormalMap
                                    , sceneProperties = sceneProperties
                                    , modelScale = modelScale
                                    , modelMatrix = modelMatrix
                                    , viewMatrix = viewMatrix
                                    , projectionMatrix = projectionMatrix
                                    }


sphere : Bool -> Bool -> Material.Textured coordinates -> Sphere3d Meters coordinates -> Entity coordinates
sphere renderObject renderShadow givenMaterial givenSphere =
    let
        (Quantity r) =
            Sphere3d.radius givenSphere

        baseEntity =
            mesh givenMaterial Primitives.sphere

        untransformedEntity =
            case ( renderObject, renderShadow ) of
                ( True, True ) ->
                    group [ baseEntity, sphereShadow givenSphere ]

                ( True, False ) ->
                    baseEntity

                ( False, True ) ->
                    sphereShadow givenSphere

                ( False, False ) ->
                    empty
    in
    untransformedEntity
        |> preScale ( r, r, r )
        |> translateBy (Vector3d.from Point3d.origin (Sphere3d.centerPoint givenSphere))


sphereShadow : Sphere3d Meters coordinates -> Entity coordinates
sphereShadow givenSphere =
    Types.Entity <|
        Types.ShadowNode <|
            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix shadowLight settings ->
                -- Note that the way the sphere shadow mesh is constructed in the vertex shaders, it
                -- will always form proper right-handed triangles regardless of the current model
                -- matrix handedness
                WebGL.entityWith (shadowSettings True settings)
                    Shaders.sphereShadowVertex
                    Shaders.shadowFragment
                    sphereShadowMesh
                    { sceneProperties = sceneProperties
                    , modelScale = modelScale
                    , modelMatrix = modelMatrix
                    , viewMatrix = viewMatrix
                    , projectionMatrix = projectionMatrix
                    , shadowLight = shadowLight
                    , constantColor = Math.Vector3.vec3 0 0 1
                    }


sphereShadowMesh : WebGL.Mesh { radiusScale : Float, angle : Float, offsetScale : Float }
sphereShadowMesh =
    let
        sphereShadowVertices =
            buildSphereShadowVertices (numStrips - 1)
                [ { radiusScale = 0, angle = 0, offsetScale = 0 }
                , { radiusScale = 0, angle = 0, offsetScale = 1 }
                ]

        sphereShadowIndices =
            buildSphereShadowIndices (numStrips - 1) []
    in
    WebGL.indexedTriangles sphereShadowVertices sphereShadowIndices


numStrips : number
numStrips =
    72


numOutlineVertices : number
numOutlineVertices =
    2 * numStrips


buildSphereShadowVertices :
    Float
    -> List { radiusScale : Float, angle : Float, offsetScale : Float }
    -> List { radiusScale : Float, angle : Float, offsetScale : Float }
buildSphereShadowVertices stripIndex accumulated =
    let
        angle =
            Float.interpolateFrom 0 (2 * pi) (stripIndex / numStrips)

        left =
            { radiusScale = 1, angle = angle, offsetScale = 0 }

        right =
            { radiusScale = 1, angle = angle, offsetScale = 1 }

        updated =
            left :: right :: accumulated
    in
    if stripIndex == 0 then
        updated

    else
        buildSphereShadowVertices (stripIndex - 1) updated


buildSphereShadowIndices : Int -> List ( Int, Int, Int ) -> List ( Int, Int, Int )
buildSphereShadowIndices stripIndex accumulated =
    let
        --   d---e
        --  /|  /|\
        -- a | / | f
        --  \|/  |/
        --   b---c
        a =
            numOutlineVertices

        b =
            2 * stripIndex

        c =
            2 * stripIndex + 1

        d =
            2 * stripIndex + 2 |> modBy numOutlineVertices

        e =
            2 * stripIndex + 3 |> modBy numOutlineVertices

        f =
            numOutlineVertices + 1

        updated =
            ( a, b, d ) :: ( b, e, d ) :: ( b, c, e ) :: ( c, f, e ) :: accumulated
    in
    if stripIndex == 0 then
        updated

    else
        buildSphereShadowIndices (stripIndex - 1) updated


block :
    Bool
    -> Bool
    -> Material.Uniform coordinates
    -> Block3d Meters coordinates
    -> Entity coordinates
block renderObject renderShadow givenMaterial givenBlock =
    let
        ( Quantity scaleX, Quantity scaleY, Quantity scaleZ ) =
            Block3d.dimensions givenBlock

        baseEntity =
            mesh givenMaterial Primitives.block

        untransformedEntity =
            case ( renderObject, renderShadow ) of
                ( True, True ) ->
                    group [ baseEntity, shadow Primitives.blockShadow ]

                ( True, False ) ->
                    baseEntity

                ( False, True ) ->
                    shadow Primitives.blockShadow

                ( False, False ) ->
                    empty
    in
    untransformedEntity
        |> preScale ( scaleX, scaleY, scaleZ )
        |> placeIn (Block3d.axes givenBlock)


cylinder :
    Bool
    -> Bool
    -> Material.Uniform coordinates
    -> Cylinder3d Meters coordinates
    -> Entity coordinates
cylinder renderObject renderShadow givenMaterial givenCylinder =
    let
        (Quantity radius) =
            Cylinder3d.radius givenCylinder

        (Quantity length) =
            Cylinder3d.length givenCylinder

        centerFrame =
            Frame3d.fromZAxis (Cylinder3d.axis givenCylinder)

        baseEntity =
            mesh givenMaterial Primitives.cylinder

        untransformedEntity =
            case ( renderObject, renderShadow ) of
                ( True, True ) ->
                    group [ baseEntity, shadow Primitives.cylinderShadow ]

                ( True, False ) ->
                    baseEntity

                ( False, True ) ->
                    shadow Primitives.cylinderShadow

                ( False, False ) ->
                    empty
    in
    untransformedEntity
        |> preScale ( radius, radius, length )
        |> placeIn centerFrame


cone :
    Bool
    -> Bool
    -> Material.Uniform coordinates
    -> Cone3d Meters coordinates
    -> Entity coordinates
cone renderObject renderShadow givenMaterial givenCone =
    let
        (Quantity radius) =
            Cone3d.radius givenCone

        (Quantity length) =
            Cone3d.length givenCone

        baseFrame =
            Frame3d.fromZAxis (Cone3d.axis givenCone)

        baseEntity =
            mesh givenMaterial Primitives.cone

        untransformedEntity =
            case ( renderObject, renderShadow ) of
                ( True, True ) ->
                    group [ baseEntity, shadow Primitives.coneShadow ]

                ( True, False ) ->
                    baseEntity

                ( False, True ) ->
                    shadow Primitives.coneShadow

                ( False, False ) ->
                    empty
    in
    untransformedEntity
        |> preScale ( radius, radius, length )
        |> placeIn baseFrame


shadow : Shadow coordinates -> Entity coordinates
shadow givenShadow =
    case shadowDrawFunction givenShadow of
        Just drawFunction ->
            Types.Entity (ShadowNode drawFunction)

        Nothing ->
            empty


shadowDrawFunction : Types.Shadow coordinates -> Maybe (Types.DrawFunction Mat4)
shadowDrawFunction givenShadow =
    case givenShadow of
        Types.EmptyShadow ->
            Nothing

        Types.Shadow _ _ webGLMesh ->
            Just <|
                \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix shadowLight settings ->
                    WebGL.entityWith (shadowSettings isRightHanded settings)
                        Shaders.shadowVertex
                        Shaders.shadowFragment
                        webGLMesh
                        { sceneProperties = sceneProperties
                        , modelScale = modelScale
                        , modelMatrix = modelMatrix
                        , viewMatrix = viewMatrix
                        , projectionMatrix = projectionMatrix
                        , shadowLight = shadowLight
                        }


triangleShadowMesh : WebGL.Mesh { triangleShadowVertex : Vec2 }
triangleShadowMesh =
    let
        triangleShadowVertices =
            [ { triangleShadowVertex = Math.Vector2.vec2 0 1 } -- 0
            , { triangleShadowVertex = Math.Vector2.vec2 1 1 } -- 1
            , { triangleShadowVertex = Math.Vector2.vec2 2 1 } -- 2
            , { triangleShadowVertex = Math.Vector2.vec2 0 -1 } -- 3
            , { triangleShadowVertex = Math.Vector2.vec2 1 -1 } -- 4
            , { triangleShadowVertex = Math.Vector2.vec2 2 -1 } -- 5
            ]

        triangleShadowFaces =
            [ ( 0, 1, 2 ) -- top
            , ( 3, 5, 4 ) -- bottom
            , ( 3, 4, 1 ) -- side 1
            , ( 3, 1, 0 )
            , ( 4, 5, 2 ) -- side 2
            , ( 4, 2, 1 )
            , ( 5, 3, 0 ) -- side 3
            , ( 5, 0, 2 )
            ]
    in
    WebGL.indexedTriangles triangleShadowVertices triangleShadowFaces


triangleShadow : Triangle3d Meters coordinates -> Entity coordinates
triangleShadow givenTriangle =
    Types.Entity <|
        Types.ShadowNode <|
            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix shadowLight settings ->
                WebGL.entityWith (shadowSettings isRightHanded settings)
                    Shaders.triangleShadowVertex
                    Shaders.shadowFragment
                    triangleShadowMesh
                    { triangleVertexPositions = triangleVertexPositions givenTriangle
                    , sceneProperties = sceneProperties
                    , modelScale = modelScale
                    , modelMatrix = modelMatrix
                    , viewMatrix = viewMatrix
                    , projectionMatrix = projectionMatrix
                    , shadowLight = shadowLight
                    }


quadShadowMesh : WebGL.Mesh { quadShadowVertex : Vec2 }
quadShadowMesh =
    let
        quadShadowVertices =
            [ { quadShadowVertex = Math.Vector2.vec2 0 1 } -- 0
            , { quadShadowVertex = Math.Vector2.vec2 1 1 } -- 1
            , { quadShadowVertex = Math.Vector2.vec2 2 1 } -- 2
            , { quadShadowVertex = Math.Vector2.vec2 3 1 } -- 3
            , { quadShadowVertex = Math.Vector2.vec2 0 -1 } -- 4
            , { quadShadowVertex = Math.Vector2.vec2 1 -1 } -- 5
            , { quadShadowVertex = Math.Vector2.vec2 2 -1 } -- 6
            , { quadShadowVertex = Math.Vector2.vec2 3 -1 } -- 7
            ]

        quadShadowFaces =
            [ ( 0, 1, 2 ) -- top
            , ( 0, 2, 3 )
            , ( 4, 6, 5 ) -- bottom
            , ( 4, 7, 6 )
            , ( 4, 5, 1 ) -- side 1
            , ( 1, 0, 4 )
            , ( 5, 6, 2 ) -- side 2
            , ( 2, 1, 5 )
            , ( 6, 7, 3 ) -- side 3
            , ( 3, 2, 6 )
            , ( 7, 4, 0 ) -- side 4
            , ( 0, 3, 7 )
            ]
    in
    WebGL.indexedTriangles quadShadowVertices quadShadowFaces


quadShadow :
    Point3d Meters coordinates
    -> Point3d Meters coordinates
    -> Point3d Meters coordinates
    -> Point3d Meters coordinates
    -> Entity coordinates
quadShadow firstPoint secondPoint thirdPoint fourthPoint =
    Types.Entity <|
        Types.ShadowNode <|
            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix shadowLight settings ->
                WebGL.entityWith (shadowSettings isRightHanded settings)
                    Shaders.quadShadowVertex
                    Shaders.shadowFragment
                    quadShadowMesh
                    { quadVertexPositions = quadVertexPositions firstPoint secondPoint thirdPoint fourthPoint
                    , sceneProperties = sceneProperties
                    , modelScale = modelScale
                    , modelMatrix = modelMatrix
                    , viewMatrix = viewMatrix
                    , projectionMatrix = projectionMatrix
                    , shadowLight = shadowLight
                    }


cullBackFaceSetting : WebGL.Settings.Setting
cullBackFaceSetting =
    WebGL.Settings.cullFace WebGL.Settings.back


cullFrontFaceSetting : WebGL.Settings.Setting
cullFrontFaceSetting =
    WebGL.Settings.cullFace WebGL.Settings.front


meshSettings : Bool -> BackFaceSetting -> List WebGL.Settings.Setting -> List WebGL.Settings.Setting
meshSettings isRightHanded backFaceSetting settings =
    case backFaceSetting of
        CullBackFaces ->
            if isRightHanded then
                cullBackFaceSetting :: settings

            else
                cullFrontFaceSetting :: settings

        KeepBackFaces ->
            settings


rightHandedStencilTest : WebGL.Settings.Setting
rightHandedStencilTest =
    StencilTest.testSeparate
        { ref = 0
        , mask = 0
        , writeMask = 0x0F
        }
        { test = StencilTest.always
        , fail = StencilTest.keep
        , zfail = StencilTest.keep
        , zpass = StencilTest.increment
        }
        { test = StencilTest.always
        , fail = StencilTest.keep
        , zfail = StencilTest.keep
        , zpass = StencilTest.decrement
        }


leftHandedStencilTest : WebGL.Settings.Setting
leftHandedStencilTest =
    StencilTest.testSeparate
        { ref = 0
        , mask = 0
        , writeMask = 0x0F
        }
        { test = StencilTest.always
        , fail = StencilTest.keep
        , zfail = StencilTest.keep
        , zpass = StencilTest.decrement
        }
        { test = StencilTest.always
        , fail = StencilTest.keep
        , zfail = StencilTest.keep
        , zpass = StencilTest.increment
        }


shadowSettings : Bool -> List WebGL.Settings.Setting -> List WebGL.Settings.Setting
shadowSettings isRightHanded settings =
    if isRightHanded then
        rightHandedStencilTest :: settings

    else
        leftHandedStencilTest :: settings


constantMesh : Vec3 -> Bounds -> WebGL.Mesh { a | position : Vec3 } -> BackFaceSetting -> Entity coordinates
constantMesh color bounds webGLMesh backFaceSetting =
    Types.Entity <|
        MeshNode bounds
            (\sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                WebGL.entityWith
                    (meshSettings isRightHanded backFaceSetting settings)
                    Shaders.plainVertex
                    Shaders.constantFragment
                    webGLMesh
                    { constantColor = color
                    , sceneProperties = sceneProperties
                    , modelScale = modelScale
                    , modelMatrix = modelMatrix
                    , viewMatrix = viewMatrix
                    , projectionMatrix = projectionMatrix
                    }
            )


colorTextureMesh : WebGL.Texture.Texture -> Bounds -> WebGL.Mesh { a | position : Vec3, uv : Vec2 } -> BackFaceSetting -> Entity coordinates
colorTextureMesh data bounds webGLMesh backFaceSetting =
    Types.Entity <|
        MeshNode bounds
            (\sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                WebGL.entityWith
                    (meshSettings isRightHanded backFaceSetting settings)
                    Shaders.unlitVertex
                    Shaders.colorTextureFragment
                    webGLMesh
                    { colorTexture = data
                    , sceneProperties = sceneProperties
                    , modelScale = modelScale
                    , modelMatrix = modelMatrix
                    , viewMatrix = viewMatrix
                    , projectionMatrix = projectionMatrix
                    }
            )


constantPointMesh : Vec3 -> Float -> Bounds -> WebGL.Mesh { a | position : Vec3 } -> Entity coordinates
constantPointMesh color radius bounds webGLMesh =
    Types.Entity <|
        PointNode bounds <|
            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                WebGL.entityWith
                    settings
                    Shaders.pointVertex
                    Shaders.constantPointFragment
                    webGLMesh
                    { constantColor = color
                    , pointRadius = radius
                    , sceneProperties = sceneProperties
                    , modelScale = modelScale
                    , modelMatrix = modelMatrix
                    , viewMatrix = viewMatrix
                    , projectionMatrix = projectionMatrix
                    }


emissiveMesh : Vec3 -> Luminance -> Bounds -> WebGL.Mesh { a | position : Vec3 } -> BackFaceSetting -> Entity coordinates
emissiveMesh color backlight bounds webGLMesh backFaceSetting =
    Types.Entity <|
        MeshNode bounds <|
            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                WebGL.entityWith
                    (meshSettings isRightHanded backFaceSetting settings)
                    Shaders.plainVertex
                    Shaders.emissiveFragment
                    webGLMesh
                    { emissiveColor = Math.Vector3.scale (Luminance.inNits backlight) color
                    , sceneProperties = sceneProperties
                    , modelScale = modelScale
                    , modelMatrix = modelMatrix
                    , viewMatrix = viewMatrix
                    , projectionMatrix = projectionMatrix
                    }


texturedEmissiveMesh : WebGL.Texture.Texture -> Luminance -> Bounds -> WebGL.Mesh { a | position : Vec3, uv : Vec2 } -> BackFaceSetting -> Entity coordinates
texturedEmissiveMesh colorData backlight bounds webGLMesh backFaceSetting =
    Types.Entity <|
        MeshNode bounds <|
            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                WebGL.entityWith
                    (meshSettings isRightHanded backFaceSetting settings)
                    Shaders.unlitVertex
                    Shaders.emissiveTextureFragment
                    webGLMesh
                    { colorTexture = colorData
                    , backlight = Luminance.inNits backlight
                    , sceneProperties = sceneProperties
                    , modelScale = modelScale
                    , modelMatrix = modelMatrix
                    , viewMatrix = viewMatrix
                    , projectionMatrix = projectionMatrix
                    }


emissivePointMesh : Vec3 -> Luminance -> Float -> Bounds -> WebGL.Mesh { a | position : Vec3 } -> Entity coordinates
emissivePointMesh color backlight radius bounds webGLMesh =
    Types.Entity <|
        PointNode bounds <|
            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings ->
                WebGL.entityWith
                    settings
                    Shaders.pointVertex
                    Shaders.emissivePointFragment
                    webGLMesh
                    { emissiveColor = Math.Vector3.scale (Luminance.inNits backlight) color
                    , pointRadius = radius
                    , sceneProperties = sceneProperties
                    , modelScale = modelScale
                    , modelMatrix = modelMatrix
                    , viewMatrix = viewMatrix
                    , projectionMatrix = projectionMatrix
                    }


lambertianMesh : Vec3 -> Bounds -> WebGL.Mesh { a | position : Vec3, normal : Vec3 } -> BackFaceSetting -> Entity coordinates
lambertianMesh color bounds webGLMesh backFaceSetting =
    Types.Entity <|
        MeshNode bounds <|
            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix ( lights, enabledLights ) settings ->
                WebGL.entityWith
                    (meshSettings isRightHanded backFaceSetting settings)
                    Shaders.uniformVertex
                    Shaders.lambertianFragment
                    webGLMesh
                    { materialColor = color
                    , sceneProperties = sceneProperties
                    , lights12 = lights.lights12
                    , lights34 = lights.lights34
                    , lights56 = lights.lights56
                    , lights78 = lights.lights78
                    , enabledLights = enabledLights
                    , modelScale = modelScale
                    , modelMatrix = modelMatrix
                    , viewMatrix = viewMatrix
                    , projectionMatrix = projectionMatrix
                    }


texturedLambertianMesh : WebGL.Texture.Texture -> Bounds -> WebGL.Mesh { a | position : Vec3, normal : Vec3, uv : Vec2 } -> BackFaceSetting -> Entity coordinates
texturedLambertianMesh materialColorData bounds webGLMesh backFaceSetting =
    Types.Entity <|
        MeshNode bounds <|
            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix ( lights, enabledLights ) settings ->
                WebGL.entityWith
                    (meshSettings isRightHanded backFaceSetting settings)
                    Shaders.texturedVertex
                    Shaders.lambertianTextureFragment
                    webGLMesh
                    { materialColorTexture = materialColorData
                    , normalMapTexture = materialColorData
                    , useNormalMap = 0.0
                    , sceneProperties = sceneProperties
                    , lights12 = lights.lights12
                    , lights34 = lights.lights34
                    , lights56 = lights.lights56
                    , lights78 = lights.lights78
                    , enabledLights = enabledLights
                    , modelScale = modelScale
                    , modelMatrix = modelMatrix
                    , viewMatrix = viewMatrix
                    , projectionMatrix = projectionMatrix
                    }


normalMappedLambertianMesh : WebGL.Texture.Texture -> WebGL.Texture.Texture -> Float -> Bounds -> WebGL.Mesh { a | position : Vec3, normal : Vec3, uv : Vec2, tangent : Vec3 } -> BackFaceSetting -> Entity coordinates
normalMappedLambertianMesh materialColorData normalMapData useNormalMap bounds webGLMesh backFaceSetting =
    Types.Entity <|
        MeshNode bounds <|
            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix ( lights, enabledLights ) settings ->
                WebGL.entityWith
                    (meshSettings isRightHanded backFaceSetting settings)
                    Shaders.normalMappedVertex
                    Shaders.lambertianTextureFragment
                    webGLMesh
                    { materialColorTexture = materialColorData
                    , normalMapTexture = normalMapData
                    , useNormalMap = useNormalMap
                    , sceneProperties = sceneProperties
                    , lights12 = lights.lights12
                    , lights34 = lights.lights34
                    , lights56 = lights.lights56
                    , lights78 = lights.lights78
                    , enabledLights = enabledLights
                    , modelScale = modelScale
                    , modelMatrix = modelMatrix
                    , viewMatrix = viewMatrix
                    , projectionMatrix = projectionMatrix
                    }


physicalMesh : Vec3 -> Float -> Float -> Bounds -> WebGL.Mesh { a | position : Vec3, normal : Vec3 } -> BackFaceSetting -> Entity coordinates
physicalMesh color roughness metallic bounds webGLMesh backFaceSetting =
    Types.Entity <|
        MeshNode bounds <|
            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix ( lights, enabledLights ) settings ->
                WebGL.entityWith
                    (meshSettings isRightHanded backFaceSetting settings)
                    Shaders.uniformVertex
                    Shaders.physicalFragment
                    webGLMesh
                    { baseColor = color
                    , roughness = roughness
                    , metallic = metallic
                    , sceneProperties = sceneProperties
                    , lights12 = lights.lights12
                    , lights34 = lights.lights34
                    , lights56 = lights.lights56
                    , lights78 = lights.lights78
                    , enabledLights = enabledLights
                    , modelScale = modelScale
                    , modelMatrix = modelMatrix
                    , viewMatrix = viewMatrix
                    , projectionMatrix = projectionMatrix
                    }


texturedPhysicalMesh : WebGL.Texture.Texture -> Vec4 -> WebGL.Texture.Texture -> Vec2 -> WebGL.Texture.Texture -> Vec2 -> Bounds -> WebGL.Mesh { a | position : Vec3, normal : Vec3, uv : Vec2 } -> BackFaceSetting -> Entity coordinates
texturedPhysicalMesh baseColorData constantBaseColor roughnessData constantRoughness metallicData constantMetallic bounds webGLMesh backFaceSetting =
    Types.Entity <|
        MeshNode bounds <|
            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix ( lights, enabledLights ) settings ->
                WebGL.entityWith
                    (meshSettings isRightHanded backFaceSetting settings)
                    Shaders.texturedVertex
                    Shaders.physicalTexturesFragment
                    webGLMesh
                    { baseColorTexture = baseColorData
                    , constantBaseColor = constantBaseColor
                    , roughnessTexture = roughnessData
                    , constantRoughness = constantRoughness
                    , metallicTexture = metallicData
                    , constantMetallic = constantMetallic
                    , normalMapTexture = baseColorData
                    , useNormalMap = 0.0
                    , sceneProperties = sceneProperties
                    , lights12 = lights.lights12
                    , lights34 = lights.lights34
                    , lights56 = lights.lights56
                    , lights78 = lights.lights78
                    , enabledLights = enabledLights
                    , modelScale = modelScale
                    , modelMatrix = modelMatrix
                    , viewMatrix = viewMatrix
                    , projectionMatrix = projectionMatrix
                    }


normalMappedPhysicalMesh : WebGL.Texture.Texture -> Vec4 -> WebGL.Texture.Texture -> Vec2 -> WebGL.Texture.Texture -> Vec2 -> WebGL.Texture.Texture -> Float -> Bounds -> WebGL.Mesh { a | position : Vec3, normal : Vec3, uv : Vec2, tangent : Vec3 } -> BackFaceSetting -> Entity coordinates
normalMappedPhysicalMesh baseColorData constantBaseColor roughnessData constantRoughness metallicData constantMetallic normalMapData useNormalMap bounds webGLMesh backFaceSetting =
    Types.Entity <|
        MeshNode bounds <|
            \sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix ( lights, enabledLights ) settings ->
                WebGL.entityWith
                    (meshSettings isRightHanded backFaceSetting settings)
                    Shaders.normalMappedVertex
                    Shaders.physicalTexturesFragment
                    webGLMesh
                    { baseColorTexture = baseColorData
                    , constantBaseColor = constantBaseColor
                    , roughnessTexture = roughnessData
                    , constantRoughness = constantRoughness
                    , metallicTexture = metallicData
                    , constantMetallic = constantMetallic
                    , normalMapTexture = normalMapData
                    , useNormalMap = useNormalMap
                    , sceneProperties = sceneProperties
                    , lights12 = lights.lights12
                    , lights34 = lights.lights34
                    , lights56 = lights.lights56
                    , lights78 = lights.lights78
                    , enabledLights = enabledLights
                    , modelScale = modelScale
                    , modelMatrix = modelMatrix
                    , viewMatrix = viewMatrix
                    , projectionMatrix = projectionMatrix
                    }


collectNodes : List (Entity coordinates) -> List Node -> List Node
collectNodes drawables accumulated =
    case drawables of
        [] ->
            accumulated

        (Types.Entity node) :: rest ->
            collectNodes rest (node :: accumulated)


group : List (Entity coordinates) -> Entity coordinates
group drawables =
    Types.Entity (Group (collectNodes drawables []))


preScale : ( Float, Float, Float ) -> Entity coordinates -> Entity coordinates
preScale scalingFactors (Types.Entity node) =
    Types.Entity (preScaleNode scalingFactors node)


preScaleNode : ( Float, Float, Float ) -> Types.Node -> Types.Node
preScaleNode scalingFactors node =
    case node of
        EmptyNode ->
            EmptyNode

        Transformed transformation underlyingNode ->
            Transformed transformation (preScaleNode scalingFactors underlyingNode)

        MeshNode bounds drawFunction ->
            MeshNode (preScaleBounds scalingFactors bounds)
                (preScaleDrawFunction scalingFactors drawFunction)

        PointNode _ _ ->
            node

        ShadowNode drawFunction ->
            ShadowNode (preScaleDrawFunction scalingFactors drawFunction)

        Group childNodes ->
            Group (List.map (preScaleNode scalingFactors) childNodes)


preScaleBounds : ( Float, Float, Float ) -> Bounds -> Bounds
preScaleBounds ( scaleX, scaleY, scaleZ ) bounds =
    let
        originalCenterPoint =
            bounds.centerPoint
    in
    { centerPoint =
        { x = scaleX * originalCenterPoint.x
        , y = scaleY * originalCenterPoint.y
        , z = scaleZ * originalCenterPoint.z
        }
    , halfX = scaleX * bounds.halfX
    , halfY = scaleY * bounds.halfY
    , halfZ = scaleZ * bounds.halfZ
    }


preScaleDrawFunction : ( Float, Float, Float ) -> Types.DrawFunction lights -> Types.DrawFunction lights
preScaleDrawFunction ( scaleX, scaleY, scaleZ ) originalDrawFunction sceneProperties modelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings =
    let
        { x, y, z, w } =
            Math.Vector4.toRecord modelScale

        updatedModelScale =
            Math.Vector4.fromRecord
                { x = x * scaleX
                , y = y * scaleY
                , z = z * scaleZ
                , w = w
                }
    in
    originalDrawFunction sceneProperties updatedModelScale modelMatrix isRightHanded viewMatrix projectionMatrix lights settings


transformBy : Transformation -> Entity coordinates1 -> Entity coordinates2
transformBy transformation (Types.Entity node) =
    case node of
        EmptyNode ->
            empty

        Transformed existingTransformation underlyingNode ->
            let
                compositeTransformation =
                    Transformation.compose existingTransformation transformation
            in
            Types.Entity (Transformed compositeTransformation underlyingNode)

        MeshNode _ _ ->
            Types.Entity (Transformed transformation node)

        PointNode _ _ ->
            Types.Entity (Transformed transformation node)

        ShadowNode _ ->
            Types.Entity (Transformed transformation node)

        Group _ ->
            Types.Entity (Transformed transformation node)


rotateAround : Axis3d Meters coordinates -> Angle -> Entity coordinates -> Entity coordinates
rotateAround axis angle givenDrawable =
    transformBy (Transformation.rotateAround axis angle) givenDrawable


translateBy : Vector3d Meters coordinates -> Entity coordinates -> Entity coordinates
translateBy displacement givenDrawable =
    transformBy (Transformation.translateBy displacement) givenDrawable


translateIn : Direction3d coordinates -> Length -> Entity coordinates -> Entity coordinates
translateIn direction distance drawable =
    translateBy (Vector3d.withLength distance direction) drawable


mirrorAcross : Plane3d Meters coordinates -> Entity coordinates -> Entity coordinates
mirrorAcross plane givenDrawable =
    transformBy (Transformation.mirrorAcross plane) givenDrawable


relativeTo : Frame3d Meters globalCoordinates { defines : localCoordinates } -> Entity globalCoordinates -> Entity localCoordinates
relativeTo frame givenDrawable =
    transformBy (Transformation.relativeTo frame) givenDrawable


placeIn : Frame3d Meters globalCoordinates { defines : localCoordinates } -> Entity localCoordinates -> Entity globalCoordinates
placeIn frame givenDrawable =
    transformBy (Transformation.placeIn frame) givenDrawable


scaleAbout : Point3d Meters coordinates -> Float -> Entity coordinates -> Entity coordinates
scaleAbout centerPoint scale givenDrawable =
    transformBy (Transformation.scaleAbout centerPoint scale) givenDrawable
