{-# LANGUAGE OverloadedStrings #-}

import Hakyll hiding (pandocCompiler)

import Site.Filters
import Site.Fields
import Site.Routes
import Site.PandocCompiler

import Data.Monoid ((<>))

myHakyllConf :: Configuration
myHakyllConf = defaultConfiguration

main :: IO ()
main = hakyllWith myHakyllConf $ do
  tags <- buildTagsWith (fmap (map slugify) . getTags) "posts/*" (fromCapture "tags/*.html")

  match ("images/**" .||. "font/*" .||. "js/*" .||. "favicon.png") $ do
    route idRoute
    compile copyFileCompiler

  match "scss/screen.scss" $ do
    route $ gsubRoute "scss/" (const "css/") `composeRoutes` setExtension "css"
    compile $ sassCompiler

  match "posts/*" $ do
    route $ nicePostRoute
    compile $ getResourceBody
      >>= withItemBody (abbreviationFilter)
      >>= pandocCompiler
      >>= loadAndApplyTemplate "templates/post.html" (tagsCtx tags <> postCtx)
      >>= loadAndApplyTemplate "templates/layout.html" postCtx

  match "pages/*" $ do
    route $ nicePageRoute
    compile $ getResourceBody
      >>= withItemBody (abbreviationFilter)
      >>= pandocCompiler
      >>= loadAndApplyTemplate "templates/page.html" postCtx
      >>= loadAndApplyTemplate "templates/layout.html" defaultCtx

  create ["404.html"] $ do
    route idRoute
    compile $ do
      makeItem ""
        >>= loadAndApplyTemplate "templates/404.html" defaultCtx
        >>= loadAndApplyTemplate "templates/layout.html" defaultCtx

  create ["index.html"] $ do
    route idRoute
    compile $ do
      makeItem ""
        >>= loadAndApplyTemplate "templates/index.html" (archiveCtx "posts/*")
        >>= loadAndApplyTemplate "templates/layout.html" defaultCtx

  tagsRules tags $ \tag pattern -> do
    let title = "Posts tagged " ++ tag
    route nicePostRoute
    compile $ do
      makeItem ""
        >>= loadAndApplyTemplate "templates/index.html" (tagsCtx tags <> archiveCtx pattern)
        >>= loadAndApplyTemplate "templates/layout.html" defaultCtx

  match "templates/*" $ compile templateCompiler

