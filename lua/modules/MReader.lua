local dirurl = '/browse-comics/?results=%s&filter=New'

function Init()
	local m = NewWebsiteModule()
	m.ID                         = 'd297f1eb6b784ded9b50d3b85cee5276'
	m.Name                       = 'MReader'
	m.RootURL                    = 'https://www.mreader.co'
	m.Category                   = 'English'
	m.OnGetDirectoryPageNumber   = 'GetDirectoryPageNumber'
	m.OnGetNameAndLink           = 'GetNameAndLink'
	m.OnGetInfo                  = 'GetInfo'
	m.OnGetPageNumber            = 'GetPageNumber'
	m.SortedList                 = true
end

function GetDirectoryPageNumber()
	if HTTP.GET(MODULE.RootURL .. dirurl:format('1')) then
		PAGENUMBER = tonumber(CreateTXQuery(HTTP.Document).XPathString('//*[@id="Result"]//ul[@class="pagination"]/li[last()-1]')) or 1
		return no_error
	else
		return net_problem
	end
end

function GetNameAndLink()
	if HTTP.GET(MODULE.RootURL .. dirurl:format((URL + 1))) then
		CreateTXQuery(HTTP.Document).XPathHREFTitleAll('//li[@class="novel-item"]/a', LINKS, NAMES)
		return no_error
	else
		return net_problem
	end
end

function GetInfo()
	MANGAINFO.URL = MaybeFillHost(MODULE.RootURL, URL)
	if HTTP.GET(MANGAINFO.URL) then
		local x = CreateTXQuery(HTTP.Document)
		MANGAINFO.Title     = x.XPathString('//h1[contains(@class, "title")]')
		MANGAINFO.CoverLink = x.XPathString('//figure[@class="cover"]/img/@data-src')
		MANGAINFO.Authors   = x.XPathString('//span[@itemprop="author"]')
		MANGAINFO.Genres    = x.XPathStringAll('//div[@class="categories"]//a')
		MANGAINFO.Status    = MangaInfoStatusIfPos(x.XPathString('//span[contains(., "Status")]/parent::*'))
		MANGAINFO.Summary   = x.XPathString('//p[@class="description"]')

		local v for v in x.XPath('//ul[@class="chapter-list"]//a').Get() do
			MANGAINFO.ChapterNames.Add(x.XPathString('strong/replace(., "-eng-li", " [EN]")', v))
			MANGAINFO.ChapterLinks.Add(v.GetAttribute('href'))
		end
		MANGAINFO.ChapterLinks.Reverse(); MANGAINFO.ChapterNames.Reverse()
		return no_error
	else
		return net_problem
	end
end

function GetPageNumber()
	if HTTP.GET(MaybeFillHost(MODULE.RootURL, URL)) then
		CreateTXQuery(HTTP.Document).XPathStringAll('//section[@class="page-in content-wrap"]//center/div/img/@src', TASK.PageLinks)
		return true
	else
		return false
	end
end
