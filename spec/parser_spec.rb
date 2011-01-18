# coding: utf-8
$KCODE = 'u'

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe RbbCode::Parser do
	context '#parse' do
		before :each do
			@parser = RbbCode::Parser.new
		end
		
        it 'should create paragraphs and line breaks' do
          bb_code = "This is one paragraph.\n\nThis is another paragraph."
          @parser.parse(bb_code).should == '<p>This is one paragraph.</p><p>This is another paragraph.</p>'
          bb_code = "This is one line.\nThis is another line."
          @parser.parse(bb_code).should == '<p>This is one line.<br/>This is another line.</p>'
        end
        
        it 'should turn [b] to <strong>' do
          @parser.parse('This is [b]bold[/b] text').should == '<p>This is <strong>bold</strong> text</p>'
        end
        
        it 'should turn [i] to <em> by default' do
          @parser.parse('This is [i]italic[/i] text').should == '<p>This is <em>italic</em> text</p>'
        end
        
        it 'should turn [u] to <u>' do
          @parser.parse('This is [u]underlined[/u] text').should == '<p>This is <u>underlined</u> text</p>'
        end
        
        it 'should turn [url]http://google.com[/url] to a link' do
          @parser.parse('Visit [url]http://google.com[/url] now').should == '<p>Visit <a href="http://google.com">http://google.com</a> now</p>'
        end
        
        it 'should turn [url=http://google.com]Google[/url] to a link' do
          @parser.parse('Visit [url=http://google.com]Google[/url] now').should == '<p>Visit <a href="http://google.com">Google</a> now</p>'
        end
        
        it 'should turn [img] to <img>' do
          @parser.parse('[img]http://example.com/image.jpg[/img]').should == '<p><img src="http://example.com/image.jpg" alt=""/></p>'
        end
        
        it 'should parse nested tags' do
          @parser.parse('[b][i]This is bold-italic[/i][/b]').should == '<p><strong><em>This is bold-italic</em></strong></p>'
        end
        
        it 'should not put <p> tags around <ul> tags' do
          @parser.parse("Text.\n\n[list]\n[*]Foo[/*]\n[*]Bar[/*]\n[/list]\n\nMore text.").should == '<p>Text.</p><ul><li>Foo</li><li>Bar</li></ul><p>More text.</p>'
        end
        
        it 'should ignore forbidden or unrecognized tags' do
          @parser.parse('There is [foo]no such thing[/foo] as a foo tag').should == '<p>There is no such thing as a foo tag</p>'
        end
        
        it 'should recover gracefully from malformed or improperly matched tags' do
          @parser.parse('This [i/]tag[/i] is malformed').should == '<p>This [i/]tag is malformed</p>'
          @parser.parse('This [i]]tag[/i] is malformed').should == '<p>This <em>]tag</em> is malformed</p>'
          @parser.parse('This [i]tag[[/i] is malformed').should == '<p>This <em>tag[</em> is malformed</p>'
          @parser.parse('This [i]tag[//i] is malformed').should == '<p>This <em>tag[//i] is malformed</em></p>'
          @parser.parse('This [[i]tag[/i] is malformed').should == '<p>This [<em>tag</em> is malformed</p>'
          @parser.parse('This [i]tag[/i]] is malformed').should == '<p>This <em>tag</em>] is malformed</p>'
          @parser.parse('This [i]i tag[i] is not properly matched').should == '<p>This <em>i tag is not properly matched</em></p>'
          @parser.parse('This i tag[/i] is not properly matched').should == '<p>This i tag is not properly matched</p>'
        end
        
        it 'should escape < and >' do
          @parser.parse('This is [i]italic[/i], but this it not <i>italic</i>.').should == '<p>This is <em>italic</em>, but this it not &lt;i&gt;italic&lt;/i&gt;.</p>'
        end
        
        it 'should work when the string begins with a tag' do
          @parser.parse('[b]This is bold[/b]').should == '<p><strong>This is bold</strong></p>'
        end
        
        it 'should handle UTF8' do
          @parser.parse("Here's some UTF-8: [i]א[/i]. And here's some ASCII text.").should == "<p>Here's some UTF-8: <em>א</em>. And here's some ASCII text.</p>"
        end
        
        # Bugs reported and fixed:
        
        it 'should not leave an open <em> tag when parsing "foo [i][/i] bar"' do
          # Thanks to Vizakenjack for finding this. It creates an empty <em> tag. Browsers don't like this, so we need to replace it.
          @parser.parse('foo [i][/i] bar').should match(/<p>foo +bar<\/p>/)
        end
        
        it 'should not raise when parsing "Are you a real phan yet?\r\n\r\n[ ] Yes\r\n[X] No"' do
          # Thanks to sblackstone for finding this.
          @parser.parse("Are you a real phan yet?\r\n\r\n[ ] Yes\r\n[X] No")
        end
        
        it 'should support images inside links' do
          # Thanks to Vizakenjack for finding this.
          @parser.parse('[url=http://www.google.com][img]http://www.123.com/123.png[/img][/url]').should ==
            '<p><a href="http://www.google.com"><img src="http://www.123.com/123.png" alt=""/></a></p>'
        end
        
        it 'can parse phpBB-style [*] tags' do
          # Thanks to motiv for finding this
          @parser.parse("[list]\n[*]one\n[*]two\n[/list]"
          ).should == '<ul><li>one</li><li>two</li></ul>'
        end
        
        context 'parsing [code] tags' do
          # Thanks to fatalerrorx for finding these
          it 'wraps the <code> tags in <pre> tags' do
            @parser.parse('The [code]some code[/code] should be preformatted').should == '<p>The <pre><code>some code</code></pre> should be preformatted</p>'
          end
          
          it 'leaves line breaks inside untouched' do
            @parser.parse("Two lines of code:\n\n[code]line 1\n\nline 2[/code]\n\nAnd some more text.").should ==
              "<p>Two lines of code:</p><p><pre><code>line 1\n\nline 2</code></pre></p><p>And some more text.</p>"
          end
          
          it 'treats tags other than the closing tag as literals' do
            @parser.parse('[code]This is [b]bold[/b] text[/code]').should == '<p><pre><code>This is [b]bold[/b] text</code></pre></p>'
          end
        end
    
    # Leave tag support
    
    it 'should parse allowed leaf tags' do
      schema = RbbCode::Schema.new
      schema.allow_tag(:br)
      html_maker = CustomHtmlMaker.new
      @parser = RbbCode::Parser.new(:schema => schema, :html_maker => html_maker)
      
      @parser.parse('This text should contain a [:br] HTML tag').should == '<p>This text should contain a <br /> HTML tag</p>'
    end
    
        # Bug from original version
        it 'should not parse multiple not closing tags' do
          schema = RbbCode::Schema.new
          schema.allow_tag(:Qsmiley)
          html_maker = CustomHtmlMaker.new
          @parser = RbbCode::Parser.new(:schema => schema, :html_maker => html_maker)
          
          @parser.parse('Two smileys: 1) [Qsmiley] and 2) [Qsmiley]').should_not == '<p>Two smileys: 1) <smiley /> and 2) <smiley /></p>'
        end
        
        it 'should parse multiple allowed leaf tags' do
          schema = RbbCode::Schema.new
          schema.allow_tag(:br)
          html_maker = CustomHtmlMaker.new
          @parser = RbbCode::Parser.new(:schema => schema, :html_maker => html_maker)
          
          @parser.parse('This text should contain a [:br] HTML tag and another one [:br]').should == '<p>This text should contain a <br /> HTML tag and another one <br /></p>'
        end
        
        it 'should parse unknown leaf tags as text' do
          @parser.parse('This text should contain a [:pseudo] BBCode tag').should == '<p>This text should contain a [:pseudo] BBCode tag</p>'
        end
    
    # Bugs
    
    it 'should not parse empty quote' do
      @parser.parse("[quote][/quote]").should == ""
    end
    
    it 'should parse quotes' do
      @parser.parse("[quote]Hallo[/quote]").should == "<blockquote>Hallo</blockquote>"
    end
		
	end
end
