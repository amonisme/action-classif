classdef ProgressBar < handle
    properties (SetAccess = protected, GetAccess = protected)
        h       % handle
        v       % value
        caption
        subTask
    end
    
    methods
        function obj = ProgressBar(title, caption, subTask)
            global SHOW_BAR;
            
            if nargin<3
                subTask = false;
            end
            
            if SHOW_BAR
                gui_active(1);
                obj.v = 0;
                obj.caption = caption;                    
                obj.h = pgManager( [], 0, caption, title);
            end        
            obj.subTask = subTask;
            if ~subTask
                str = sprintf('%s\n', title);
                write_log(str);
                
                if ~isempty(caption)
                    str = sprintf('  --> %s\n', caption);
                    write_log(str);
                end
            end
        end
        
        function obj = progress(obj, value)
            global SHOW_BAR;
            
            if SHOW_BAR
                if(~gui_active)
                    stop_parallel_computing();
                    throw(MException('','Execution aborted by user.'));
                end

                obj.v = value;
                obj.h = pgManager( obj.h, obj.v);
            end
        end
        
        function obj = setCaption(obj, caption)
            global SHOW_BAR;
            
            if SHOW_BAR
                obj.caption = caption;
                obj.h = pgManager( obj.h, obj.v, caption);
            end
            if ~isempty(caption) && ~obj.subTask
                str = sprintf('  --> %s\n', caption);
                write_log(str);
            end
        end
        
        function obj = setTitle(obj, title)
            global SHOW_BAR;
            
            if SHOW_BAR
                obj.h = pgManager(obj.h, obj.v, obj.caption, title);
            end
            if ~obj.subTask
                str = sprintf('%s\n', title);
                write_log(str);
            end
        end
        
        function obj = close(obj)
            global SHOW_BAR;
            
            if SHOW_BAR
                obj.h = pgManager( obj.h, -1);
            end
            if ~obj.subTask
                str = sprintf('\n');
                write_log(str);
            end
        end
    end
    
end

