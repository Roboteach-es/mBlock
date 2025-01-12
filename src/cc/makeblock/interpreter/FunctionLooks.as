/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// LooksPrims.as
// John Maloney, April 2010
//
// Looks primitives.

package cc.makeblock.interpreter {
	import blockly.runtime.FunctionProvider;
	import blockly.runtime.Thread;
	
	import blocks.Block;
	
	import interpreter.Interpreter;
	
	import scratch.ScratchObj;
	import scratch.ScratchSprite;
	import scratch.ScratchStage;
	
	import translation.Translator;

	internal class FunctionLooks {


	public function FunctionLooks() {
	}

	public function addPrimsTo(provider:FunctionProvider):void {
		provider.register('lookLike:', primShowCostume);
		provider.register('nextCostume', primNextCostume);
		provider.register('costumeIndex', primCostumeIndex);
		provider.register('costumeName', primCostumeName);

		provider.register('showBackground:', primShowCostume); // used by Scratch 1.4 and earlier (doesn't start scene hats)
		provider.register('nextBackground', primNextCostume); // used by Scratch 1.4 and earlier (doesn't start scene hats)
		provider.register('backgroundIndex', primSceneIndex);
		provider.register('sceneName', primSceneName);
		provider.register('nextScene', function(thread:Thread, argList:Array):void { startScene('next backdrop');thread.requestRedraw(); });
		provider.register('startScene', function(thread:Thread, argList:Array):void { startScene(argList[0]);thread.requestRedraw(); });
		provider.register('startSceneAndWait', function(thread:Thread, argList:Array):void { 
			var threadList:Array = startScene(argList[0]); 
			thread.requestRedraw();
			thread.suspend();
			thread.suspendUpdater = [PrimInit.checkSubThreadFinish, threadList];
		});

		provider.register("say:", onSay);
		provider.register("think:", onThink);
		provider.register('say:duration:elapsed:from:', function(thread:Thread, argList:Array):void { showBubbleAndWait(thread, argList[0], argList[1], 'talk') });
		provider.register('think:duration:elapsed:from:', function(thread:Thread, argList:Array):void { showBubbleAndWait(thread, argList[0], argList[1], 'think') });

		provider.register('changeGraphicEffect:by:', primChangeEffect);
		provider.register('setGraphicEffect:to:', primSetEffect);
		provider.register('filterReset', primClearEffects);

		provider.register('changeSizeBy:', primChangeSize);
		provider.register('setSizeTo:', primSetSize);
		provider.register('scale', primSize);

		provider.register('show', primShow);
		provider.register('hide', primHide);

		provider.register('comeToFront', primGoFront);
		provider.register('goBackByLayers:', primGoBack);

		provider.register('setVideoState', primSetVideoState);
		provider.register('setVideoTransparency', primSetVideoTransparency);

		provider.register('setRotationStyle', primSetRotationStyle);
	}
	
	static private function onThink(thread:Thread, argList:Array):void
	{
		if(ThreadUserData.getScratchObj(thread) is ScratchStage){
			return;
		}
		showBubble(thread, argList[0], "think");
	}
	
	static private function onSay(thread:Thread, argList:Array):void
	{
		if(ThreadUserData.getScratchObj(thread) is ScratchStage){
			return;
		}
		showBubble(thread, argList[0], "talk");
	}
	
	static private function showBubble(thread:Thread, value:Object, type:String):void
	{
		var text:String;
		if(typeof value == "number" && value != int(value)){
			text = value.toFixed(3);
		}else if(!(value is String)){
			text = value.toString();
		}else{
			text = value as String;
		}
		var s:ScratchSprite = ThreadUserData.getScratchSprite(thread);
		if(null == s || null == text){
			return;
		}
		s.showBubble(text, type);
		if(s.visible) thread.requestRedraw();
	}

	private function primNextCostume(thread:Thread, argList:Array):void {
		var s:ScratchObj = ThreadUserData.getScratchObj(thread);
		if (s != null) s.showCostume(s.currentCostumeIndex + 1);
		if(s.visible) thread.requestRedraw();
	}

	private function primShowCostume(thread:Thread, argList:Array):void {
		var s:ScratchObj = ThreadUserData.getScratchObj(thread);
		if (s == null) return;
		var arg:* = argList[0];
		if (typeof(arg) == 'number') {
			s.showCostume(arg - 1);
		} else {
			var i:int = s.indexOfCostumeNamed(arg);
			if (i >= 0) {
				s.showCostume(i);
			} else if ('previous costume' == arg) {
				s.showCostume(s.currentCostumeIndex - 1);
			} else if ('next costume' == arg) {
				s.showCostume(s.currentCostumeIndex + 1);
			} else {
				var n:Number = Interpreter.asNumber(arg);
				if (!isNaN(n)) s.showCostume(n - 1);
				else return; // arg did not match a costume name nor is it a valid number
			}
		}
		if(s.visible) thread.requestRedraw();
	}

	private function primCostumeIndex(thread:Thread, argList:Array):void {
		var s:ScratchObj = ThreadUserData.getScratchObj(thread);
		thread.push( (s == null) ? 1 : s.costumeNumber());
	}

	private function primCostumeName(thread:Thread, argList:Array):void {
		var s:ScratchObj = ThreadUserData.getScratchObj(thread);
		thread.push( (s == null) ? '' : s.currentCostume().costumeName);
	}

	private function primSceneIndex(thread:Thread, argList:Array):void {
		thread.push( mBlockRT.app.stagePane.costumeNumber());
	}

	private function primSceneName(thread:Thread, argList:Array):void {
		thread.push( mBlockRT.app.stagePane.currentCostume().costumeName);
	}

	private function startScene(s:String):Array {
		if ('next backdrop' == s) s = backdropNameAt(mBlockRT.app.stagePane.currentCostumeIndex + 1);
		else if ('previous backdrop' == s) s = backdropNameAt(mBlockRT.app.stagePane.currentCostumeIndex - 1);
		else {
			var n:Number = Interpreter.asNumber(s);
			if (!isNaN(n)) {
				n = (Math.round(n) - 1) % mBlockRT.app.stagePane.costumes.length;
				if (n < 0) n += mBlockRT.app.stagePane.costumes.length;
				s = mBlockRT.app.stagePane.costumes[n].costumeName;
			}
		}
		function findSceneHats(stack:Block, target:ScratchObj):void {
			if ((stack.op == "whenSceneStarts") && (stack.args[0].argValue == s)) {
				receivers.push([stack, target]);
			}
		}
		var receivers:Array = [];
		mBlockRT.app.stagePane.showCostumeNamed(s);
		mBlockRT.app.runtime.allStacksAndOwnersDo(findSceneHats);
		var threadList:Array = [];
		for each(var item:Array in receivers){
			threadList.push(mBlockRT.app.interp.toggleThread(item[0], item[1]));
		}
		return threadList;
	}

	private function backdropNameAt(i:int):String {
		var costumes:Array = mBlockRT.app.stagePane.costumes;
		return costumes[(i + costumes.length) % costumes.length].costumeName;
	}

	private function showBubbleAndWait(thread:Thread, text:String, secs:Number, type:String):void {
		var s:ScratchSprite = ThreadUserData.getScratchSprite(thread);
		if (s == null) return;
		s.showBubble(text, type);
		if(s.visible) thread.requestRedraw();
		thread.suspend();
		thread.suspendUpdater = [__CheckTimeOut, s, text, secs * 1000];
	}

	static private function __CheckTimeOut(thread:Thread, s:ScratchSprite, text:String, timeout:int):void
	{
		if(thread.timeElapsedSinceSuspend < timeout){
			return;
		}
		thread.resume();
		if (s.bubble && (s.bubble.getText() == Translator.map(text))) s.hideBubble();
	}

	private function primChangeEffect(thread:Thread, argList:Array):void {
		var s:ScratchObj = ThreadUserData.getScratchObj(thread);
		if (s == null) return;
		var delta:Number = argList[1];
		if(delta == 0) return;
		var filterName:String = argList[0];

		var newValue:Number = s.filterPack.getFilterSetting(filterName) + delta;
		s.filterPack.setFilter(filterName, newValue);
		s.applyFilters();
		if (s.visible || s == mBlockRT.app.stagePane) thread.requestRedraw();
	}

	private function primSetEffect(thread:Thread, argList:Array):void {
		var s:ScratchObj = ThreadUserData.getScratchObj(thread);
		if (s == null) return;
		var filterName:String = argList[0];
		var newValue:Number = argList[1]
		if(s.filterPack.setFilter(filterName, newValue))
			s.applyFilters();
		if (s.visible || s == mBlockRT.app.stagePane) thread.requestRedraw();
	}

	private function primClearEffects(thread:Thread, argList:Array):void {
		var s:ScratchObj = ThreadUserData.getScratchObj(thread);
		s.clearFilters();
		s.applyFilters();
		if (s.visible || s == mBlockRT.app.stagePane) thread.requestRedraw();
	}

	private function primChangeSize(thread:Thread, argList:Array):void {
		var s:ScratchSprite = ThreadUserData.getScratchSprite(thread);
		if (s == null) return;
		var oldScale:Number = s.scaleX;
		s.setSize(s.getSize() + Number(argList[0]));
		if (s.visible && (s.scaleX != oldScale)) thread.requestRedraw();
	}

	private function primSetRotationStyle(thread:Thread, argList:Array):void {
		var s:ScratchSprite = ThreadUserData.getScratchSprite(thread);
		var newStyle:String = argList[0];
		if ((s == null) || (newStyle == null)) return;
		s.setRotationStyle(newStyle);
	}

	private function primSetSize(thread:Thread, argList:Array):void {
		var s:ScratchSprite = ThreadUserData.getScratchSprite(thread);
		if (s == null) return;
		s.setSize(Number(argList[0]));
		if(s.visible)thread.requestRedraw();
	}

	private function primSize(thread:Thread, argList:Array):void {
		var s:ScratchSprite = ThreadUserData.getScratchSprite(thread);
		thread.push(s ? Math.round(s.getSize()) : 100);
	}

	private function primShow(thread:Thread, argList:Array):void {
		var s:ScratchSprite = ThreadUserData.getScratchSprite(thread);
		if (s == null) return;
		s.visible = true;
		s.applyFilters();
		s.updateBubble();
		if(s.visible)thread.requestRedraw();
	}

	private function primHide(thread:Thread, argList:Array):void {
		var s:ScratchSprite = ThreadUserData.getScratchSprite(thread);
		if ((s == null) || !s.visible) return;
		s.visible = false;
		s.applyFilters();
		s.updateBubble();
		thread.requestRedraw();
	}


	private function primGoFront(thread:Thread, argList:Array):void {
		var s:ScratchSprite = ThreadUserData.getScratchSprite(thread);
		if ((s == null) || (s.parent == null)) return;
		s.parent.setChildIndex(s, s.parent.numChildren - 1);
		if(s.visible)thread.requestRedraw();
	}

	private function primGoBack(thread:Thread, argList:Array):void {
		var s:ScratchSprite = ThreadUserData.getScratchSprite(thread);
		if ((s == null) || (s.parent == null)) return;
		var newIndex:int = s.parent.getChildIndex(s) - Number(argList[0]);
		newIndex = Math.max(minSpriteLayer(), Math.min(newIndex, s.parent.numChildren - 1));

		if (newIndex > 0 && newIndex < s.parent.numChildren) {
			s.parent.setChildIndex(s, newIndex);
			if(s.visible)thread.requestRedraw();
		}
	}

	private function minSpriteLayer():int {
		// Return the lowest sprite layer.
		var stg:ScratchStage = mBlockRT.app.stagePane;
		return stg.getChildIndex(stg.videoImage ? stg.videoImage : stg.penLayer) + 1;
	}

	private function primSetVideoState(thread:Thread, argList:Array):void {
		mBlockRT.app.stagePane.setVideoState(argList[0]);
	}

	private function primSetVideoTransparency(thread:Thread, argList:Array):void {
		mBlockRT.app.stagePane.setVideoTransparency(Number(argList[0]));
		mBlockRT.app.stagePane.setVideoState('on');
	}

}}
